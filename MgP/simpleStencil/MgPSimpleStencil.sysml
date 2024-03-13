package MgPSimpleStencil {
    part def Person;
    part def Machine;
    part distributionContext {
        part driver[1]: Person;
        connect driver to truck;
        part truck: Machine {
            port bed;
        }
        flow from loader.toTruck to truck.bed;
        part loader[2]: Machine {
            port fromSorter;
            port toTruck;
        }
        flow from sorter.toLoader to loader.fromSorter;
        part sorter[1]: Machine {
            port fromPicker;
            port toLoader;
        }
        flow from picker.toSorter to sorter.fromPicker;
        part picker[3]: Person {
            port toSorter;
        }
    }
}