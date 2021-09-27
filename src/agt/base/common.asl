

+!create_and_focus_ldfu : true <-
    .my_name(NAME);
    .concat("ldfu_artifact_",NAME, NAME_ART);
    makeArtifact(NAME_ART,"org.hypermedea.LinkedDataFuSpider",["get.n3",true],ART_ID);
    focus(ART_ID);
    .

+!create_and_focus_itemRandomizer : seed(SEED) <-
    .my_name(NAME);
    .concat("IntRandomizer_artifact_",NAME, NAME_ART);
    makeArtifact(NAME_ART,"IntRandomizer",[SEED],ART_ID);
    focus(ART_ID);
.
    

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }