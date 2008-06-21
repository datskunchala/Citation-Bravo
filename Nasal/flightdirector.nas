#############################################################################
# Flight Director/Autopilot controller.
# Syd Adams
#
# HDG:
# Heading Bug hold - Low Bank can be selected
# NAV:
# Arm & Capture VOR , LOC or FMS
# APR : (ILS approach)
# Arm & Capture VOR APR , LOC or BC
# Also arm and capture GS
# BC :
# Arm & capture localizer backcourse
# Nav also illuminates
# VNAV:
# Arm and capture VOR/DME or FMS vertical profile
# profile entered in MFD VNAV menu
# ALT:
# Hold current Altitude or PFD preset altitude
# VS:
# Hold current vertical speed
# adjustable with pitch wheel
# SPD :
# Hold current speed 
# adjustable with pitch wheel
#
#############################################################################
# lnav 
#0=W-LVL , 1=HDG , 2=NAV Arm ,3=NAV Cap , 4=LOC arm , 5=LOC Cap , 6=FMS
# vnav
# 0=PITCH,  1=VNAV, 2=ALT hold , 3=VS , 4=GS arm ,5 = GS cap
#FlightDirector/Autopilot 
# ie: var fltdir = flightdirector.new(property);

var ap_settings = gui.Dialog.new("/sim/gui/dialogs/primus-autopilot/dialog",
        "Aircraft/Citation-Bravo/Systems/autopilot-dlg.xml");

var flightdirector = {
    new : func(fdprop){
        m = {parents : [flightdirector]};
        m.lnav_text=["ROLL","HDG","NAV-ARM","NAV","LOC-ARM","LOC","LNAV"];
        m.vnav_text=["PTCH","VNAV","ALT","VS","GS-ARM","GS"];
        m.spd_text=["","IAS","speed-with-pitch"];
        m.LAT=["ROL","HDG","HDG","VOR","HDG","LOC","LNAV"];
        m.subLAT=["   ","   ","VOR","   ","LOC","   ","   "];
        m.VRT=["PIT","VNAV","ALT","VS","   ","GS"];
    m.subVRT=["   ","GS"];
    m.node = props.globals.getNode(fdprop,1);
        m.yawdamper = props.globals.getNode("autopilot/locks/yaw-damper",1);
        m.yawdamper.setBoolValue(0);
        m.lnav = m.node.getNode("lnav",1);
        m.lnav.setIntValue(0);
        m.vnav = m.node.getNode("vnav",1);
        m.vnav.setIntValue(0);
        m.gs_arm = m.node.getNode("gs-arm",1);
        m.gs_arm.setBoolValue(0);
        m.asel = m.node.getNode("Asel",1);
        m.asel.setDoubleValue(0);
        m.speed = m.node.getNode("spd",1);
        m.speed.setDoubleValue(0);
        m.DH = props.globals.getNode("autopilot/route-manager/min-lock-altitude-agl-ft",1);
        m.Defl = props.globals.getNode("instrumentation/nav/heading-needle-deflection");
        m.GSDefl = props.globals.getNode("instrumentation/nav/gs-needle-deflection");
        m.NavLoc = props.globals.getNode("instrumentation/nav/nav-loc");
        m.hasGS = props.globals.getNode("instrumentation/nav/has-gs");
        m.Valid = props.globals.getNode("instrumentation/nav/in-range");
        m.FMS = props.globals.getNode("instrumentation/primus1000/dc550/fms",1);
        m.NAV = props.globals.getNode("instrumentation/primus1000/dc550/nav",1);
        m.AP_hdg = props.globals.getNode("/autopilot/locks/heading",1);
        m.AP_hdg.setValue(m.lnav_text[0]);
        m.AP_hdg_setting = props.globals.getNode("/autopilot/settings/heading",1);
        m.AP_hdg_setting.setDoubleValue(0);
        m.AP_spd_setting = props.globals.getNode("/autopilot/settings/target-speed-kt",1);
        m.AP_spd_setting.setDoubleValue(0);
        m.AP_alt = props.globals.getNode("/autopilot/locks/altitude",1);
        m.AP_alt.setValue(m.vnav_text[0]);
        m.AP_spd = props.globals.getNode("/autopilot/locks/speed",1);
        m.AP_spd.setValue(m.spd_text[0]);
        m.AP_off = props.globals.getNode("/autopilot/locks/passive-mode",1);
        m.AP_off.setBoolValue(1);
    
    m.AP_lat_annun = m.node.getNode("LAT-annun",1);
        m.AP_lat_annun.setValue(" ");
    m.AP_sublat_annun = m.node.getNode("LAT-arm-annun",1);
        m.AP_sublat_annun.setValue(" ");
    m.AP_vert_annun = m.node.getNode("VRT-annun",1);
        m.AP_vert_annun.setValue(" ");
    m.AP_subvert_annun = m.node.getNode("VRT-arm-annun",1);
        m.AP_subvert_annun.setValue(" ");

        m.pitch_active=props.globals.getNode("/autopilot/locks/pitch-active",1);
        m.pitch_active.setBoolValue(1);
        m.roll_active=props.globals.getNode("/autopilot/locks/roll-active",1);
        m.roll_active.setBoolValue(1);
        m.bank_limit=m.node.getNode("bank-limit-switch",1);
        m.bank_limit.setBoolValue(0);

        m.max_pitch=m.node.getNode("pitch-max",1);
        m.max_pitch.setDoubleValue(10);
        m.min_pitch=m.node.getNode("pitch-min",1);
        m.min_pitch.setDoubleValue(-10);
        m.max_roll=m.node.getNode("roll-max",1);
        m.max_roll.setDoubleValue(27);
        m.min_roll=m.node.getNode("roll-min",1);
        m.min_roll.setDoubleValue(-27);
    return m;
    },
    ############################
    set_lateral_mode : func(lnv){
    var tst =me.lnav.getValue();
    if(lnv ==tst)lnv=0;
        if(lnv==4){
            if(!me.NavLoc.getBoolValue()){
                lnv=2;
            }else{
                if(me.hasGS.getBoolValue())me.gs_arm.setBoolValue(1);
            }
        }
        if(lnv==2){
            if(me.FMS.getBoolValue())lnv = 6;
            }
        me.lnav.setValue(lnv);
        me.AP_hdg.setValue(me.lnav_text[lnv]);
    },
###########################
    set_vertical_mode : func(vnv){
    var tst =me.vnav.getValue();
    if(vnv ==tst)vnv=0;
        if(vnv==1){
            if(!me.FMS.getBoolValue()){
                vnv = 0;
            }else{
                var tmpalt =getprop("autopilot/route-manager/route/wp/altitude-ft");
                if(tmpalt < 0)tmpalt=30000;
                setprop("autopilot/settings/target-altitude-ft",tmpalt);
            }
        }
        if(vnv==2){
        var asel=getprop("instrumentation/altimeter/indicated-altitude-ft");
        asel = int(asel * 0.01) * 100;
        setprop("autopilot/settings/target-altitude-ft",asel);
        }
        me.vnav.setValue(vnv);
        me.AP_alt.setValue(me.vnav_text[vnv]);
    },
###########################
    set_course : func(nvnum,crs){
        var rd =0;
        if(!me.FMS.getBoolValue()){
            rd = getprop("instrumentation/nav["~nvnum~"]/radials/selected-deg");
            if(crs ==0){
                rd=int(getprop("orientation/heading-magnetic-deg"));
            }else{
                rd = rd+crs;
                if(rd >360)rd =rd-360;
                if(rd <1)rd = rd +360;
            }
            setprop("instrumentation/nav["~nvnum~"]/radials/selected-deg",rd);
        }
    },
###########################
    set_hdg_bug : func(hbg){
        var rd =0;
            rd = getprop("autopilot/settings/heading-bug-deg");
            if(rd==nil)rd=0;
            if(hbg ==0){
                rd=int(getprop("orientation/heading-magnetic-deg"));
            }else{
                rd = rd+hbg;
                if(rd >360)rd =rd-360;
                if(rd <1)rd = rd +360;
            }
            setprop("autopilot/settings/heading-bug-deg",rd);
    },
###########################
    ias_set : func(spd){
        var rd =0;
            rd = me.AP_spd_setting.getValue();
            if(rd==nil)rd=0;
            if(spd ==0){
                rd=0;
            }else{
                rd = rd+spd;
                if(rd >400)rd =400;
                if(rd <0)rd = 0;
            }
            me.AP_spd_setting.setValue(rd);
    },
#### button press handler####
    set_mode : func(mode){
        if(mode=="hdg"){
            me.set_lateral_mode(1);
        }elsif(mode=="nav"){
            me.set_lateral_mode(2);
        }elsif(mode=="apr"){
            me.set_lateral_mode(4);
        }elsif(mode=="bc"){
            var tst=me.lnav.getValue();
            var bcb = getprop("instrumentation/nav/back-course-btn");
            bcb = 1-bcb;
            if(tst <2 and tst >5)bcb = 0;
            setprop("instrumentation/nav/back-course-btn",bcb);
        }elsif(mode=="vnav"){
            me.set_vertical_mode(1);
        }elsif(mode=="alt"){
            me.set_vertical_mode(2);
        }elsif(mode=="vs"){
            me.set_vertical_mode(3);
        }elsif(mode=="ias"){
            var sp=me.speed.getValue();
            sp=1-sp;
            me.speed.setValue(sp);
            var kt= int(getprop("velocities/airspeed-kt"));
            me.AP_spd_setting.setValue(kt);
            me.AP_spd.setValue(me.spd_text[sp]);
        }
    },
#### check AP errors####
    check_AP_limits : func(){
        var apmode = me.AP_off.getBoolValue();
        var agl=getprop("/position/altitude-agl-ft");
        if(!apmode){
            var maxroll = getprop("/orientation/roll-deg");
            var maxpitch = getprop("/orientation/pitch-deg");
            if(maxroll > 65 or maxroll < -65){
                apmode = 1;
            }
            if(maxpitch > 30 or maxpitch < -20){
                apmode = 1;
                setprop("controls/flight/elevator-trim",0);
            }
            if(agl < 180)apmode = 1;
            me.AP_off.setBoolValue(apmode);
        }
        if(agl < 50)me.yawdamper.setBoolValue(0);
        return apmode;
    },
#### update lnav####
    update_lnav : func(){
        var lnv = me.lnav.getValue();
        if(lnv   >1 and lnv<6){
        if(me.FMS.getBoolValue())lnv=6;
    }
    if(lnv==2){
        var defl = me.Defl.getValue();
        if(me.Valid.getBoolValue()){
            if(defl <= 9 and defl >= -9)lnv=3;
        }
    }elsif(lnv==4){
        var defl = me.Defl.getValue();
        if(me.Valid.getBoolValue()){
            if(defl <= 9 and defl >= -9)lnv=5;
        }
    }
    me.lnav.setValue(lnv);
        me.AP_hdg.setValue(me.lnav_text[lnv]);
    me.AP_lat_annun.setValue(me.LAT[lnv]);
    me.AP_sublat_annun.setValue(me.subLAT[lnv]);
    },
#### update vnav####
    update_vnav : func(){
        var vnv = me.vnav.getValue();
        if(me.gs_arm.getBoolValue()){
            if(me.lnav.getValue() ==5){
                var defl = me.GSDefl.getValue();
                if(defl < 1 and defl > -1){
                    vnv=5;
                    me.gs_arm.setBoolValue(0);
                }
            }
        }
    me.vnav.setValue(vnv);
        me.AP_alt.setValue(me.vnav_text[vnv]);
    me.AP_vert_annun.setValue(me.VRT[vnv]);
    me.AP_subvert_annun.setValue(me.subVRT[me.gs_arm.getValue()]);
    },
#### autopilot engage####
    toggle_autopilot : func(apmd){
        var md1=0;
        if(apmd=="ap"){
            md1 = me.AP_off.getBoolValue();
            md1=1-md1;
            if(getprop("/position/altitude-agl-ft") < 180)md1=1;
            me.AP_off.setBoolValue(md1);
            if(md1==0)me.yawdamper.setBoolValue(1);
        }elsif(apmd=="yd"){
            md1 = me.yawdamper.getBoolValue();
            md1=1-md1;
            me.yawdamper.setBoolValue(md1);
            if(md1==0)me.AP_off.setBoolValue(1);
        }elsif(apmd=="bank"){
            md1 = me.bank_limit.getBoolValue();
            md1=1-md1;
            me.bank_limit.setBoolValue(md1);
            if(md1==1){
                me.max_roll.setValue(14);
                me.min_roll.setValue(-14);
            }else{
                me.max_roll.setValue(27);
                me.min_roll.setValue(-27);
            }
        }
    },
#### pitch wheel####
    pitch_wheel : func(amt){
        var factor=amt;
        var vmd = me.vnav.getValue();
        var ptc=0;
            var mx=0;
            var mn=0;
        if(vmd==0){
            mx=me.max_pitch.getValue();
            mn=me.min_pitch.getValue();
            ptc = getprop("autopilot/settings/target-pitch-deg");
            if(ptc==nil)ptc=0;
            ptc=ptc+0.10 *  amt;
            if(ptc>mx)ptc=mx;
            if(ptc<mn)ptc=mn;
            setprop("autopilot/settings/target-pitch-deg",ptc);
        }elsif(vmd==3){
            mx=6000;
            mn=-6000;
            ptc = getprop("autopilot/settings/vertical-speed-fpm");
            if(ptc==nil)ptc=0;
            ptc=ptc+100 *amt;
            if(ptc>mx)ptc=mx;
            if(ptc<mn)ptc=mn;
            setprop("autopilot/settings/vertical-speed-fpm",ptc);
        }
    },
#### roll knob ###
    roll_knob : func(rl){
    }
};

var FlDr=flightdirector.new("instrumentation/flightdirector");

######################################

setlistener("/sim/signals/fdm-initialized", func {
    setprop("autopilot/settings/target-altitude-ft",10000);
    setprop("autopilot/settings/heading-bug-deg",0);
    setprop("autopilot/settings/vertical-speed-fpm",0);
    setprop("autopilot/settings/target-pitch-deg",0);
    settimer(update_fd, 5);
    print("Flight Director ...Check");
});

var update_fd = func {
var APoff = FlDr.check_AP_limits();
FlDr.update_lnav();
FlDr.update_vnav();
settimer(update_fd, 0); 
}
