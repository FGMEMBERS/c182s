##########################################
#
# Aircraft states
#
# This script provides functions to get the aircraft into a defined state.
# The idea is that the checklist-states define states of the plane after conducting the checklist.
# Common functions are centralized in specific functions.
# The autostart- and state-functions then provide "bundles" of those checklists and override items if needed.
##########################################


####################
# Common helpers   #
####################
var setAvionics = func(state) {
    setprop("/controls/switches/AVMBus1", 0);  
    setprop("/controls/switches/AVMBus2", 0);
    setprop("/instrumentation/audio-panel/power-btn", state);
    setprop("/instrumentation/audio-panel/volume-ics-pilot", state);
    setprop("/controls/switches/kt-76c", state);
    setprop("/controls/switches/kn-62a", state);
    setprop("/instrumentation/nav[0]/power-btn", state);
    setprop("/instrumentation/nav[1]/power-btn", state);
    setprop("/instrumentation/comm[0]/power-btn", state);
    setprop("/instrumentation/comm[1]/power-btn", state);
    setprop("/instrumentation/comm[0]/volume-selected", state);
    setprop("/instrumentation/comm[1]/volume-selected", state);
    setprop("/controls/switches/kn-62a-mode", state);
    setprop("/instrumentation/adf[0]/power-btn", state);
}

var secureAircraftOnGround = func(state) {
    # Secure on ground, but wait for after init time to avoid "the weird aircraft dance"
    var t = getprop("/sim/time/elapsed-sec") or 0;
    if (t <= 0.30) {
        # recall sometime later in case sim just started
        settimer(func(){ secureAircraftOnGround(state);}, 0.30);
        return;
    }
    
    setprop("/sim/chocks001/enable", state);
    setprop("/sim/chocks002/enable", state);
    setprop("/sim/chocks003/enable", state);
    setprop("/sim/model/c182s/securing/pitot-cover-visible", state);
    setprop("/sim/model/c182s/securing/tiedownL-visible", state);
    setprop("/sim/model/c182s/securing/tiedownR-visible", state);
    setprop("/sim/model/c182s/securing/tiedownT-visible", state);
}

var setEngineRunning = func(rpm, throttle, mix, prop) {
    repair_damage();
    reset_fuel_contamination();
    
    setprop("/controls/flight/flaps", 0);
    setprop("/controls/engines/engine/cowl-flaps-norm", 1);
    setprop("/controls/gear/brake-parking", 1);
    setprop("/controls/lighting/nav-lights", 1);
    setprop("/controls/lighting/strobe", 1);
    setprop("/controls/lighting/beacon", 1);
    setprop("/controls/switches/starter", 0);
    setprop("/controls/engines/engine[0]/magnetos", 3);
    setprop("/controls/engines/engine[0]/master-bat", 1);
    setprop("/controls/engines/engine[0]/master-alt", 1);
    setprop("/sim/model/c182s/cockpit/control-lock-placed", 0);
    setprop("/controls/switches/fuel_tank_selector", 2);
    setprop("/engines/engine/external-heat/enabled", 0);
    setAvionics(0); # OFF for start
    
    #let engine run
    setprop("/sim/start-state-internal/oil-temp-override", 1); # override disables coughing due to low oil temp
    settimer(func{ setprop("/sim/start-state-internal/oil-temp-override", 0); }, 240); # disable override after this time
    autostart(0, 0, 1);
    setprop("/controls/engines/engine[0]/throttle", throttle);
    setprop("/controls/engines/engine[0]/mixture-lever", mix);
    setprop("/controls/engines/engine[0]/propeller-pitch", prop);
    setprop("/controls/switches/AVMBus1", 1);
    setprop("/controls/switches/AVMBus2", 1);
    
    # Instant-on does not work currently... but would be preferable!
    #setprop("/consumables/fuel/tank[5]/level-gal_us", 0.5);
    #setprop("/fdm/jsbsim/propulsion/tank[5]/pct-full", 0.5);
    #setprop("/fdm/jsbsim/propulsion/tank[5]/priority", 1);
    #setprop("/fdm/jsbsim/running", 1);
    #setprop("/fdm/jsbsim/propulsion/engine/set-running", 1);
    #setprop("/engines/engine[0]/rpm", rpm);
    #setprop("/engines/engine[0]/running", 1);
    
    setprop("/controls/flight/elevator-trim", 0);
    setprop("/controls/flight/rudder-trim", 0);
    
    # Avionics ON
    setAvionics(1);

};



####################
# Checklist states #
####################
var checklist_afterLanding = func() {
    setprop("/controls/flight/flaps", 0);
    setprop("/controls/engines/engine/cowl-flaps-norm", 1);
}

var checklist_secureAircraft = func() {
    setprop("/controls/gear/brake-parking", 1);
    setprop("/controls/engines/engine[0]/throttle", 0.0);
    setprop("/controls/lighting/nav-lights", 0);
    setprop("/controls/lighting/strobe", 0);
    setprop("/controls/lighting/beacon", 0);
    setAvionics(0);
    setprop("/controls/engines/engine[0]/mixture-lever", 0.0);
    setprop("/controls/switches/starter", 0);
    setprop("/controls/engines/engine[0]/magnetos", 0);
    setprop("/controls/engines/engine[0]/master-bat", 0);
    setprop("/controls/engines/engine[0]/master-alt", 0);
    setprop("/sim/model/c182s/cockpit/control-lock-placed", 1);
    setprop("/controls/switches/fuel_tank_selector", 1);
}
        
var checklist_preflight = func() {
    reset_fuel_contamination();
    
    # Checking for minimal oil level
    var oil_level = getprop("/engines/engine/oil-level");
    if (oil_level < 6) {
        setprop("/engines/engine/oil-level", 8.0);
    }

    # Checking for minimal fuel level
    var fuel_level_left  = getprop("/consumables/fuel/tank[0]/level-norm");
    var fuel_level_right = getprop("/consumables/fuel/tank[1]/level-norm");
    if (fuel_level_left < 0.25)
        setprop("/consumables/fuel/tank[0]/level-norm", 0.25);
    if (fuel_level_right < 0.25)
        setprop("/consumables/fuel/tank[1]/level-norm", 0.25);
    
    setprop("/sim/model/c182s/cockpit/control-lock-placed", 0);
    setprop("/controls/gear/brake-parking", 1);
    secureAircraftOnGround(0);
}




####################
# State settings   #
####################

var state_coldAndDark = func() {
    repair_damage();
    checklist_afterLanding();
    checklist_secureAircraft();
    secureAircraftOnGround(1);
    
    setprop("/controls/flight/elevator-trim", 0);
    setprop("/controls/flight/rudder-trim", 0);
    
    # lights off
    setprop("/controls/lighting/dome-light-r", 0);
    setprop("/controls/lighting/dome-light-l", 0);
    setprop("/controls/lighting/dome-exterior-light", 0);
    setprop("/controls/lighting/instrument-lights-norm", 0);
    setprop("/controls/lighting/glareshield-lights-norm", 0);
    setprop("/controls/lighting/pedestal-lights-norm", 0);
    setprop("/controls/lighting/radio-lights-norm", 0);
    
    setprop("/sim/start-state-internal/oil-temp-override", 0);
};

var state_readyForTakeoff = func() {
    repair_damage();
    reset_fuel_contamination();
    secureAircraftOnGround(0);
    setEngineRunning(1000, 0.1, 1, 1);
};

var state_cruising = func() {
    repair_damage();
    reset_fuel_contamination();
    secureAircraftOnGround(0);
    setEngineRunning(2000, 1, 0.9, 0.80);  # TODO: Mix should be calculated by altitude
    setprop("/controls/gear/brake-parking", 0);
    setprop("/controls/engines/engine/cowl-flaps-norm", 0);
}





##########################################
# Apply selected state
##########################################
var applyAircraftState = func() {
    var stateAuto   = getprop("/sim/start-state_auto") or 0;
    var stateSaved  = getprop("/sim/start-state_saved") or 0;
    var stateCnD    = getprop("/sim/start-state_CnD") or 0;
    var stateRfT    = getprop("/sim/start-state_RfT") or 0;
    var stateCruise = getprop("/sim/start-state_Crs") or 0;
    
    if (stateAuto == 1) {
        # get from presets
        var prs_onground = getprop("/sim/presets/onground") or "";
        var prs_parkpos  = getprop("/sim/presets/parkpos") or "";
        var prs_rwy      = getprop("/sim/presets/runway") or "";
        
        if (prs_onground) {
            # either parking or runway/taxi/elsewhere
            if (prs_parkpos != "") {
                # currently has a bug with parkpos name "0" because this gets initialized to "" by fgfs
                print("Apply state: Automatic (parking->ColdAndDark)");
                state_coldAndDark();
            } else {
                print("Apply state: Automatic (not-parking->ReadyForTakeoff)");
                state_readyForTakeoff();
            }
        } else {
            # somewhere in the air
            print("Apply state: Automatic (in-air->cruise)");
            state_cruising();
        }
    }
    if (stateSaved == 1) {
        # do nothing, flightgear already has initialized
        print("Apply state: saved");
    }
    if (stateCnD == 1) {
        print("Apply state: Cold-and-Dark");
        state_coldAndDark();
    }
    if (stateRfT == 1) {
        print("Apply state: Ready-for-Takeoff");
        state_readyForTakeoff();
    }
    if (stateCruise == 1) {
        print("Apply state: cruise");
        state_cruising();
    }
};



##########################################
# Autostart
#  Parameters:
#   - msg          Print gui messages
#   - delay        seconds for delay of start
#   - setStates    for invocation by init-states
##########################################
var autostart = func (msg=1, delay=1, setStates=0) {
    print("Autostart engine engaged.");
    if (getprop("/fdm/jsbsim/propulsion/engine/set-running") and !setStates) {
        # When engine already running, perform autoshutdown
        if (msg)
            gui.popupTip("Autoshutdown engine engaged.", 5);
                
        #After landing
        checklist_afterLanding();
        
        # Shutdown engine
        setprop("/controls/engines/engine[0]/throttle", 0.0);
        setprop("/controls/engines/engine[0]/mixture-lever", 0.0);
        setprop("/controls/switches/starter", 0);

        #Securing Aircraft
        checklist_secureAircraft();
        
        #securing Aircraft on ground
        secureAircraftOnGround(1);
        
        print("Autoshutdown engine complete.");
        return;
    }
    
    # Repair Aircraft
    # This repairs any damage, reloads battery, removes water contamination, etc
    repair_damage();
    reset_fuel_contamination();
    

    # Filling fuel tanks
    setprop("/consumables/fuel/tank[0]/selected", 1);
    setprop("/consumables/fuel/tank[1]/selected", 1);

    # Setting levers and switches for startup
    setprop("/controls/switches/fuel_tank_selector", 2);
    setprop("/controls/engines/engine[0]/magnetos", 3);
    setprop("/controls/engines/engine[0]/throttle", 0.2);
    setprop("/controls/engines/engine[0]/mixture-lever", 1.0);
    setprop("/controls/engines/engine[0]/propeller-pitch", 1);
    setprop("/controls/engines/engine/cowl-flaps-norm", 1);
    setprop("/controls/engines/engine[0]/fuel-pump", 0);
    setprop("/controls/flight/elevator-trim", 0.0);
    setprop("/controls/flight/rudder-trim", 0.0);
    setprop("/controls/engines/engine[0]/master-bat", 1);
    setprop("/controls/engines/engine[0]/master-alt", 1);
    setAvionics(0);

    # Setting lights
    setprop("/controls/lighting/nav-lights", 1);
    setprop("/controls/lighting/strobe", 1);
    setprop("/controls/lighting/beacon", 1);

    # Setting flaps to 0
    setprop("/controls/flight/flaps", 0.0);

    # Set the altimeter
    var pressure_sea_level = getprop("/environment/pressure-sea-level-inhg");
    setprop("/instrumentation/altimeter/setting-inhg", pressure_sea_level);

    # Set heading offset
    var magnetic_variation = getprop("/environment/magnetic-variation-deg");
    setprop("/instrumentation/heading-indicator/offset-deg", -magnetic_variation);

    # Pre-flight inspection
    checklist_preflight();

    
    # Ensure disabled complex-engine-procedures
    # (so engine always starts)
    var complexEngineProcedures_state_old = getprop("/engines/engine/complex-engine-procedures");
    setprop("/engines/engine/complex-engine-procedures", 0);

    
    
    
    # All set, starting engine
    settimer(func {
        setprop("/controls/switches/starter", 1);
        setprop("/engines/engine[0]/auto-start", 1);
    }, delay);

    var engine_running_check_delay = 6.0;
    settimer(func {
        if (!getprop("/fdm/jsbsim/propulsion/engine/set-running")) {
            gui.popupTip("The autostart failed to start the engine. You must lean the mixture and start the engine manually.", 5);
            print("Autostart engine FAILED");
        }
        setprop("/controls/switches/starter", 0);
        setprop("/engines/engine[0]/auto-start", 0);
        
        # Reset complex-engine-procedures user setting
        setprop("/engines/engine/complex-engine-procedures", complexEngineProcedures_state_old);
        
        
        # Set switches to after-start state
        if (!setStates) {
            setprop("/controls/switches/AVMBus1", 1);
            setprop("/controls/switches/AVMBus2", 1);
        }

        
        print("Autostart engine complete.");
        
    }, engine_running_check_delay);
    

};




####################
# INIT STATE
####################
setlistener("/sim/signals/fdm-initialized", func {
    if (getprop("/sim/start-state_RfT") == nil) setprop("/sim/start-state_RfT", 1);  #init default
    settimer(applyAircraftState, 0.5); # runs myFunc after 2 seconds
});
