package loader;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.util.HashMap;
import java.util.Map;


import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdfconnection.RDFConnection;
import org.apache.jena.rdfconnection.RDFConnectionFactory;


/**
 * @author : Noé SAFFAF
 * @since : 21/08/2021, sam.
 **/
public class GraphLoader {

    private static final String rootPath = "graph/";
    private static final String[] folderNames  = {"Door/","Key/","Room/"};
    private static final String rootURI = "http://localhost:3030/atacDungeon";

    public static void main(String[] args) {
        runGraphLoader();
    }

    private static void runGraphLoader(){
        Map<String,String> mapFilenamePath = new HashMap<>();
        for (String folderName : folderNames){
            File folder = new File(rootPath+folderName);
            for (File file : folder.listFiles()) {
                if (file.isFile()) {
                    String name = file.getName().replace(".ttl","");
                    mapFilenamePath.put(rootPath+folderName+file.getName(),name);
                }
            }
        }

        String graphStore = rootURI + "/data";
        String sparqlEndpoint = rootURI + "/sparql";
        String sparqlUpdate = rootURI + "/update";
        Model model;
        for (String filenamePath : mapFilenamePath.keySet()){
            model = ModelFactory.createDefaultModel();
            try {
                model.read(new FileInputStream(filenamePath),null,"TTL");
            } catch (FileNotFoundException e){
                e.printStackTrace();
                return;
            }
            RDFConnection conneg = RDFConnectionFactory.connect(sparqlEndpoint,sparqlUpdate,graphStore);
            conneg.load(mapFilenamePath.get(filenamePath),model);
        }
    }
}
