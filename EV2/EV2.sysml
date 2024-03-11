//* -*- coding: utf-8 -*- ********************************************************
 * SysMLv2 EV2 example
 *    Hisashi Miyashita <himi@mgnite.com>
 *******************************************************************************/

package EV2 {
    import SI::*;
    import StateSpaceRepresentation::*;

    import MgS::*;
    import Quantities::*;
    import MeasurementReferences::*;
    
    attribute <'A⋅h'> 'ampere hour'  : ElectricChargeUnit = A*h;

    attribute def TorqueCoefficientUnit :> DerivedUnit {
        private attribute lengthPF: QuantityPowerFactor[1] { :>> quantity = isq.L; :>> exponent = 2; }
        private attribute massPF: QuantityPowerFactor[1] { :>> quantity = isq.M; :>> exponent = 1; }
        private attribute durationPF: QuantityPowerFactor[1] { :>> quantity = isq.T; :>> exponent = -2; }
        private attribute electricCurrentPF: QuantityPowerFactor[1] { :>> quantity = isq.I; :>> exponent = -1; }
        attribute :>> quantityDimension { :>> quantityPowerFactors = (lengthPF, massPF, durationPF, electricCurrentPF); }
    }

    attribute <'N⋅m/A'> 'newton metre per ampere' : TorqueCoefficientUnit = N*m/A;
    attribute torquePerCurrent :> Quantities::scalarQuantities = ISQ::torque / ISQ::electricCurrent;


    package EVlib {
        abstract action def EVlib :> MgS::RefSimSubsystem {
            doc /* EVlib definition */
            attribute :>> refSubsystemModelLocation = "EV2/EVlib";
            @MgS::Style { property = "BackgroundColor=lightBlue;Position=[0,0,65,50];";}
        }

        action def Motor :> EVlib {
            @MgS::Style { property = "BackgroundColor=orange;Position=[0,0,70,50];";}
            in attribute :>> input {
                attribute voltage :> ISQ::electricPotential;
                attribute friction :> ISQ::torque;
            }

            attribute <motR> resistance :> ISQ::resistance { @MgS::Param; }
            attribute <motL> inductance :> ISQ::inductance { @MgS::Param; }
            attribute <Km> torqueCoeff :> torquePerCurrent { @MgS::Param; }

            out attribute :>> output {
                attribute current :> ISQ::electricCurrent;
                attribute torque :> ISQ::torque;
            }
        }

        action def Battery :> EVlib {
            @MgS::Style { property = "BackgroundColor=red;Position=[0,0,70,50];";}
            in attribute :>> input {
                attribute current :> ISQ::electricCurrent;
            }

            attribute <V0> baseVoltage :> ISQ::electricPotential { @MgS::Param; }
            attribute <SOCinit> socInit :> MgUnits::ratio { @MgS::Param; }
            attribute <Bcapacity> capacity :> ISQ::electricCharge { @MgS::Param; }
            attribute <Rint> internalResistance :> ISQ::resistance { @MgS::Param; }

            out attribute :>> output {
                attribute voltage :> ISQ::electricPotential;
            }
        }

        action def Tire :> EVlib {
            @MgS::Style { property = "BackgroundColor=yellow;Position=[0,0,60,50];";}
            in attribute :>> input {
                attribute torque :> ISQ::torque;
                attribute accel :> ISQ::acceleration;
            }

            attribute <R> radius :> ISQ::length { @MgS::Param; }
            attribute <J> moment :> ISQ::momentOfInertia { @MgS::Param; }

            out attribute :>> output {
                attribute force :> ISQ::force;
                attribute <outTorque> torque :> ISQ::torque;
            }
        }

        action def Reducer :> EVlib {
            @MgS::Style { property = "BackgroundColor=white;Position=[0,0,70,50];";}
            in attribute :>> input {
                attribute torque :> ISQ::torque;
            }

            attribute gearRatio : ScalarValues::Real { @MgS::Param; }

            out attribute :>> output {
                attribute <outTorque> torque :> ISQ::torque;
            }
        }
    }

    part def Vehicle {
        @MgS::SimModel { name = "EV2"; }
        attribute mass :> ISQ::mass { @MgS::Param { name = "m"; } }
        attribute efficiency;

        attribute def VehicleInput :> Input {
            attribute force :> ISQ::force;
        }

        attribute def VehicleOutput :> Output {
            attribute accel :> ISQ::acceleration;
            attribute velocity :> ISQ::speed;
            attribute distance :> ISQ::distance;
        }

        attribute def VehicleState :> StateSpace {
            attribute velocity :> ISQ::speed;
            attribute distance :> ISQ::distance;
        }

        #simBlock action vehicleBehavior {
            in :>> input : VehicleInput;
            out :>> output : VehicleOutput;
            :>> stateSpace : VehicleState;
        }
        
        action powerTrain : MgS::SimSubsystem {
            @MgS::Style { property = "autoLayout=true;";}
            in attribute :>> input {
                attribute voltage :> ISQ::electricPotential;
                attribute accel :> ISQ::acceleration;
            }
            out attribute :>> output {
                attribute current :> ISQ::electricCurrent;
                attribute force :> ISQ::force;
            }
        }
    }

    requirement def VehicleRequirement {
        in vehicle : Vehicle;
    }

    analysis def VehicleAnalysis :> MgS::SimAnalysis {
        subject vehicle : Vehicle;
        requirement vehicleRequirement : VehicleRequirement;
    }

    requirement def RangeRequirement :> VehicleRequirement {
        doc /* The range of EV must be longer than the required spec under the flat road. */
        attribute actualRange : LengthValue;
        attribute requiredRange : LengthValue;

        require constraint { actualRange >= requiredRange }
    }

    analysis def RangeAnalysis :> VehicleAnalysis {
        requirement rangeRequirement :>> vehicleRequirement : RangeRequirement {
            :>> actualRange = simulatedRange;
        }

        objective rangeAnalysisObjective {
            doc /* This analysis is to estimate the range of
                 * the EV by simulating the vehicle driving under the compact vehicle regulation.
                 */
            require rangeRequirement;
        }
        return simulatedRange : LengthValue;
    }

    requirement def EfficiencyRequirement :> VehicleRequirement {
        doc /* The efficiency of EV must be better than the required spec. */
        attribute actualEfficiency;
        attribute requiredEfficiency;

        require constraint { actualEfficiency >= requiredEfficiency }
    }

    analysis def EfficiencyAnalysis :> VehicleAnalysis {
        requirement efficiencyRequirement :>> vehicleRequirement : EfficiencyRequirement {
            attribute :>> actualEfficiency = simulatedEfficiency;
        }

        objective efficiencyAnalysisObjective {
            require efficiencyRequirement;
        }
        return simulatedEfficiency;
    }

    requirement def MaxSpeedRequirement :> VehicleRequirement {
        doc /* The maximum speed of EV must be larger than the required spec. */
        attribute actualMaxSpeed :> ISQ::speed;
        attribute requiredMaxSpeed :> ISQ::speed;
    }

    analysis def MaxSpeedAnalysis :> VehicleAnalysis {
        requirement maxSpeedRequirement :>> vehicleRequirement : MaxSpeedRequirement {
            attribute :>> actualMaxSpeed = simulatedMaxSpeed;
        }

        objective maxSpeedAnalysisObjective {
            require maxSpeedRequirement;
        }
        
        return simulatedMaxSpeed :> ISQ::speed;
    }

    part baseVehicle : Vehicle {
        /* airFrictionCoefficient [kg / m] = 1/2 * rho[kg/m^3] * Cd * S[m^2],
         * where rho is air density, S is front projected area. */
        attribute airFrictionCoefficient default 0.2 { @MgS::Param; }

        action battery : EVlib::Battery {
            :>> baseVoltage default 300[V];
            :>> capacity default 70['A⋅h'];
            :>> socInit default 0.8;
            :>> internalResistance default 1.8['Ω'];
        }

        action voltage : MgS::Scope {
            :>> num = 1;
        }

        flow battery.output.voltage to voltage.input.i1;

        flow bv2pv from battery.output.voltage to powerTrain.input.voltage;
        flow pc2bc from powerTrain.output.current to battery.input.current;

        flow va2pa from vehicleBehavior.output.accel to powerTrain.input.accel;
        flow pf2vf from powerTrain.output.force to vehicleBehavior.input.force;
    }
}
