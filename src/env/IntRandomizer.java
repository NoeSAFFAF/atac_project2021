import cartago.Artifact;
import cartago.OPERATION;
import cartago.OpFeedbackParam;

import java.util.*;
import java.util.concurrent.ThreadLocalRandom;


/**
 * @author : Noé SAFFAF
 * @since : 26/09/2021, dim.
 **/

public class IntRandomizer extends Artifact {
    private Integer index;
    private Random rand;

    public void init(int seed) {
        index = -1;
        rand = new Random();
        rand.setSeed(seed);
    }

    @OPERATION
    public void addInteger(OpFeedbackParam<Integer> r_i){
        index++;
        r_i.set(index);
    }

    @OPERATION
    public void pickRandomInteger(OpFeedbackParam<Integer> r_i){
        Integer randomInt = rand.nextInt(index+1);
        r_i.set(randomInt);
        index = -1;
    }

}
