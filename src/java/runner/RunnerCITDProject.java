package runner;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.util.HashMap;
import java.util.Map;


import jason.JasonException;
import org.apache.jena.fuseki.main.FusekiServer;
import org.apache.jena.query.DatasetFactory;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.rdfconnection.RDFConnection;
import org.apache.jena.rdfconnection.RDFConnectionFactory;
import org.apache.jena.sparql.core.DatasetGraph;
import org.hypermedea.LinkedDataFuSpider;


/**
 * @author : Noé SAFFAF
 * @since : 21/08/2021, sam.
 **/
public class RunnerCITDProject {

    private static final String rootPath = "graph/";
    private static final String[] folderNames  = {"Door/","Key/","Room/"};
    private static final String rootURI = "http://localhost:3030/atacDungeon/";
    private static final Map<String,String> mapFilenamePath = new HashMap<>();

    private static FusekiServer server;

    public static void main(String[] args) {
        runFileMapping();
        runServer();
        runGraphLoader();
        runJacamoProject();
    }

    private static void runFileMapping(){
        mapFilenamePath.clear();
        for (String folderName : folderNames){
            File folder = new File(rootPath+folderName);
            for (File file : folder.listFiles()) {
                if (file.isFile()) {
                    String name = file.getName().replace(".ttl","");
                    mapFilenamePath.put(rootPath+folderName+file.getName(),name);
                }
            }
        }
    }

    private static void runServer(){

        FusekiServer.Builder builder = FusekiServer.create();
        for (String name : mapFilenamePath.values()){
            DatasetGraph ds = DatasetFactory.createTxnMem().asDatasetGraph();
            builder.add("/atacDungeon/"+name, ds);
        }
        server = builder.port(3030).build() ;
        server.start() ;
    }

    private static void runGraphLoader(){
        Model model;
        for (String filenamePath : mapFilenamePath.keySet()){
            model = ModelFactory.createDefaultModel();
            try {
                model.read(new FileInputStream(filenamePath),null,"TTL");
            } catch (FileNotFoundException e){
                e.printStackTrace();
                return;
            }
            String graphStore = rootURI + mapFilenamePath.get(filenamePath) + "/data";
            String sparqlEndpoint = rootURI + mapFilenamePath.get(filenamePath) +"/sparql";
            String sparqlUpdate = rootURI + mapFilenamePath.get(filenamePath) +"/update";
            RDFConnection conneg = RDFConnectionFactory.connect(sparqlEndpoint,sparqlUpdate,graphStore);
            conneg.load(model);
        }
    }

    private static void runJacamoProject() {
        String[] args = {"dungeon.jcm"};
        try {
            jacamo.infra.JaCaMoLauncher.main(args);
        } catch (JasonException e){
            e.printStackTrace();
        }

    }
}
