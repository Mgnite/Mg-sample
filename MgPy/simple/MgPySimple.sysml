package MgPyExample1 {
    import SI::*;
    part def Vehicle {
        attribute mass default 1200[kg];
        state vehicleState {
            entry action init;
            then state stop;
            then state run;
        }
    }
}