/*
 * biomass curves in SVG
 * 
  generated 
   * var Sliders
   * var Scenarios
  */

var pnames = {};

var ntabs;
var Years = 60;
var Model;

// value sequence functions

function offset_data(pts,a) {
    npts = [];
    for (var i =0; i<pts.length;i+=1) {
       npt = pts[i]-a;
       npts.push(npt); 
    }
    return npts;
}

function zero_point(pts) {
    zero = 0;
    for (var year in pts) 
         if (pts[year]<0) zero=year;   
    if (zero==0) 
        return 0;
    else {
         for (var year = 1;year<pts.length;year++)         
              if (pts[year-1] < 0 && pts[year] > 0) 
              return year-1  +  (- pts[year-1] / (- pts[year-1]+ pts[year]));               
         return -1;         
         }
}

function select_sequence(data,field) {
    var seq= data.map(function(year,index) {
              return year[field];
    });
    return seq;
}

// controls 
function def_sliders() {
    for (let i=0;i<Sliders.length;i++) {
        var slider = Sliders[i];
 //       $('#slidername'+i).text(slider.name);
        $('#p-'+i).val(slider.initial); 
        pnames[slider.id]=i;
        $('#slider'+i ).slider({
           min:slider.min,
           max:slider.max,
           value:slider.initial,
           step:slider.step,
           slide: function(event, ui) {
                     $('#p-'+i).val(ui.value);
                     refresh();  
                  }
           });
      }
//      console.log("Pnames ",pnames);
}


function parsefloat(s) {
    if (s=="") 
       return 0
    else 
        return parseFloat(s);  
}

function round(number,precision) {
    var factor = Math.pow(10, precision);
    var tempNumber = number * factor;
    var roundedTempNumber = Math.round(tempNumber);
    return roundedTempNumber / factor;
}

function format_number(num) {
  return num.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,')
}

function get_number(id) {
    var i = pnames[id];
    return parsefloat($("#p-"+i).val()); 
}

function set_number(id,val) {
    var i = pnames[id];
    var slider=Sliders[i];
    $('#slider'+i ).slider({value:val});
    $('#p-'+i).val(val);
}

function summary_refresh() {
    set_number("DBH",parseFloat($("#summary-DBH").val()));  
    set_number("NRep",parseFloat($("#summary-NRep").val()));
    btrs = $("#summary_use_BTRS").prop("checked");
    $("#use_BTRS").prop("checked",btrs);
    refresh();
}

function refresh() { 
    set_BTRS();
    set_same_species();
    compute_model();
    create_table();
    create_summary()
    create_graph();  
    create_small_graph();
}

// model setup

function set_scenario(i) {
    scenario=Scenarios[i];
    n_scenarios = $('.scenario').length;
    Object.keys(scenario).forEach(function (item) {
        set_number(item,scenario[item]);
    });
    $('#scenario').html(scenario.title);
    btrs = scenario.BTRS == '';
    $("#use_BTRS").prop("checked",btrs);
    $("#summary_use_BTRS").prop("checked",btrs);
    same_species =scenario.Samespecies =='';
    console.log("same_species",same_species);
    $("#same_species").prop("checked",same_species);
    console.log($("#same_species").prop("checked"));
    $('#scenario'+i).css("background-color","lightgreen");
    for (var j=0;j<n_scenarios;j++)
       if (j != i) 
          $('#scenario'+j).css("background-color","white");        
    refresh()
}

function dbh_to_BTRS(dbh) {
    n= dbh < 15 ? 0
           : dbh >= 80 ? 8
           : Math.floor( dbh / 10);
    return n;
}

function is_BTRS() {
    return $("#use_BTRS").prop("checked");
}

function set_BTRS() {
    if (is_BTRS()) {
        dbh=get_number("DBH");
        btrs=dbh_to_BTRS(dbh);
        set_number('NRep',btrs);
        $("#summary-NRep").val(btrs);
//     console.log("BTRS",btrs);
    }
}

function set_same_species() {
   var same_species = $("#same_species").is(":checked");
   if (same_species) {
       set_number('RepA',get_number("A"));
       set_number('RepB',get_number("B"));
       set_number('RepRR',get_number("RR"));
       set_number('RepAM',get_number("AM"));
       set_number('RepHL',get_number("HL"));
  }   
}

// biomass modeling

function dbh_to_cavat(dbh) {
   var cavat_unit_value = 15.88;
   var cavat_CTI_factor = 1.5;
   var cavat_functional_factor = 0.75;
   var cavat_life_factor = 0.95;
   var r=dbh/2;
   return Math.round(cavat_unit_value * Math.PI * r * r * cavat_functional_factor * cavat_life_factor);
}

function dbh_to_biomass(dbh,a,b) {
    return Math.exp(a + b*Math.log(dbh)) /1000;
}

function biomass_to_CO2(bm) {
    return bm*0.5*3.66666;
}

function half_life_to_pm(years) {
    return (1 - Math.pow(0.1,1/years))*100;
}

function dbh_to_age(dbh,ring_radius,age_at_maturity) {
    rbh = 10 * dbh / 2;
    core_radius = age_at_maturity * ring_radius;
//    console.log("rbh",rbh,core_radius);
    if (rbh <= core_radius) {
         return rbh / ring_radius
    }
    else {
        core_radius_1 = core_radius - ring_radius;
        core_area = Math.PI * Math.pow(core_radius,2);
        core_area_1 = Math.PI * Math.pow(core_radius_1,2);
        CAI = core_area - core_area_1;
        current_area = Math.PI * Math.pow(rbh,2);
        growth_area = current_area - core_area;
        growth_years = growth_area/ CAI;
        return  age_at_maturity + growth_years;
    } 
}

function age_to_dbh(age,ring_radius,age_at_maturity) {
    if (age ==0) 
         return 0;
    else if (age <= age_at_maturity) 
         return 2 * ring_radius * age / 10;
    else {
        core_radius = age_at_maturity * ring_radius;
        core_area = Math.PI * Math.pow(core_radius,2);
        core_radius_1 = core_radius - ring_radius;
        core_area_1 = Math.PI * Math.pow(core_radius_1,2);
        CAI = core_area - core_area_1;
        CAI_growth = CAI * (age - age_at_maturity);
        total_radius = Math.sqrt((core_area + CAI_growth) / Math.PI);
        return 2*total_radius /10;
     } 
}

function tree_data() {
    var bmp = []; 
    var DBH = get_number("DBH");
    var ring_radius =  get_number("RepRR");
    var age_at_maturity = get_number("RepAM");

    var age= dbh_to_age(DBH,ring_radius,age_at_maturity);

    var age_at_maturity = get_number("AM");
    var ring_radius =  get_number("RR");
    var a = get_number("A");
    var b = get_number("B");
    var pc_canopy = get_number("CP");
    var treehl = get_number ("HL") - age;
    var tree_mortality = half_life_to_pm(treehl);
//    console.log("mortality",tree_mortality);
    var dbh = age_to_dbh(age,ring_radius,age_at_maturity);
    var base_biomass =  pc_canopy/100 * dbh_to_biomass(dbh,a,b);
    var base_CO2 =biomass_to_CO2(base_biomass);
//    console.log("tree mortality", treehl,tree_mortality);
//   console.log(DBH,age_at_maturity,ring_radius,age,a,b);
    for (var year=0;year<Years;year+=1) {
           dbh = age_to_dbh(age+year,ring_radius,age_at_maturity);
           bm =  dbh_to_biomass(dbh,a,b);
           bm_adj = Math.pow(1-tree_mortality/100,year) * pc_canopy/100 * bm;
           CO2 = biomass_to_CO2(bm_adj);
           rel_CO2 = CO2 - base_CO2;
           bmp.push({DBH:dbh, biomass: bm_adj, CO2: CO2, rel_CO2: rel_CO2});
    }
//    console.log(bmp);
    return bmp;
}

function replacement_data() {
    var rp = []; 
    var number_planted = get_number('NRep');
    var planting_delay = get_number("PD");
    var age_at_planting = get_number("AP");
    var establishment_years = get_number("EY");
    var ring_radius =  get_number("RepRR");
    var age_at_maturity = get_number("RepAM");
    var a = get_number("RepA");
    var b = get_number("RepB");
    var rephl = get_number ("RepHL") - age_at_planting ;
    var tree_mortality = half_life_to_pm(rephl);
//   console.log("rep-mortality",rephl,tree_mortality);

    for (var year=0;year<Years;year+=1) {
           age = year < planting_delay ? 0 
                  : year < planting_delay + establishment_years ? age_at_planting
                  : age_at_planting + year  - planting_delay - establishment_years;                 
           dbh = age_to_dbh(age,ring_radius,age_at_maturity);
           bm =  number_planted * dbh_to_biomass(dbh,a,b);
           bm_adj = age == 0 ? 0 : Math.pow(1-tree_mortality/100,year - age_at_planting) * bm;
           CO2 = biomass_to_CO2(bm_adj);
           rp.push(CO2);
    }
//    console.log(rp);
    return rp;
}

function decay_data(tree_CO2) {
    var decay_years = get_number("Decay");   
    var dp = [];
    for (var year=0;year<Years;year+=1) {
        decay = decay_years == 0 ? 0
                : year <= decay_years ? tree_CO2 * year /decay_years
                : tree_CO2;
        dp.push(decay);
    }
 //   console.log(dp);
    return dp;
}

function benefit_data(tree_data,replacement_data,decay_data){
    var bp = [];
    for (var year=0;year<Years;year+=1) {
        benefit = replacement_data[year] - tree_data[year] - decay_data[year];
        bp.push(benefit);
   }
//   console.log(bp);
   return bp;  
}

function compute_model() {
   Model={};
   Years  = parseFloat($("#Years").val())+5;
   Model.DBH = get_number("DBH");
   var ring_radius =  get_number("RepRR");
   var age_at_maturity = get_number("RepAM");
   Model.age = dbh_to_age(Model.DBH,ring_radius,age_at_maturity);

// tree biomass curve
   Model.tree_pts = tree_data();
   Model.base_CO2 = Model.tree_pts[0]['CO2'];  
   Model.base_CO2_value = Model.base_CO2 * 60;
   Model.cavat = dbh_to_cavat(Model.DBH);
   Model.decay_pts = decay_data(Model.base_CO2);
   
// replacement biomass curve
   Model.NRep =  get_number('NRep');

   Model.rep_pts = replacement_data();
   
//   console.log(rep_pts);
   Model.benefit_pts = benefit_data(select_sequence(Model.tree_pts,"rel_CO2"),Model.rep_pts,Model.decay_pts);
    
   Model.breakeven = zero_point(Model.benefit_pts);

// console.log(Model);   
}

function solve_breakeven () {
    target_year= parseFloat($('#target-year').val());
    set_number("DBH",parseFloat($("#summary-DBH").val()));  

    $("#use_BTRS").prop("checked",false);
    $("#summary_use_BTRS").prop("checked",false);

    var reps= 1;
    set_number("NRep",reps)
    compute_model();
    while ( Model.breakeven == -1 || Math.round(Model.breakeven) > target_year ) {
        reps++;
        set_number("NRep",reps);
//       console.log(reps);
        compute_model();
    }
    create_table();
    create_summary()
    create_graph();  
    create_small_graph();

}

function create_summary(){

   var current_year = new Date().getFullYear();
   var net_2030 =Model.benefit_pts[2030-current_year];
   var net_2050 =Model.benefit_pts[2050-current_year];
   var color_2030 = net_2030 < 0 ? "red" : "green"
   var color_2050 = net_2050 < 0 ? "red" : "green"
   $('#summary-DBH').val(Model.DBH);
   $('#summary-age').html("<span>"+Math.round(Model.age)+"</span>");
   $('#summary-NRep').val(Model.NRep);
   $('#summary_use_BTRS').prop('checked',$('#use_BTRS').prop('checked'));
   
//   $('#summary-replacements').html("<span>"+Model.NRep +" trees " + (is_BTRS() ? " following BTRS guidelines" : "")+"</span>");
//   $('#tree-biomass').html("<span>"+Model.tree_pts[0].biomass.toFixed(3)+" tonnes</span>");
   $('#tree-CO2').html("<span style='color:red'>"+( -Model.base_CO2.toFixed(3))+" tonnes</span>");
   $('#CO2-2030').html("<span style='color:"+color_2030+"'>"+net_2030.toFixed(3)+" tonnes</span>");
   $('#CO2-2050').html("<span style='color:"+color_2050+"'>"+net_2050.toFixed(3)+" tonnes</span>");
//  $('#cavat_value').html("<span> £"+format_number(Model.cavat)+"</span>");
//  $('#tree-CO2-value').html("<span> £" + Model.base_CO2_value.toFixed(2)+"</span>");
   breakeven_text = Model.breakeven == -1 ? " beyond " + Years + " years"
                 : Model.breakeven == 0 ? "always a benefit"
                 : Math.round(Model.breakeven) + " years";
   $('#breakeven').html("<span>"+breakeven_text+"</span>");
}

function create_table() {
    var table="<table border='1'>";
    table += "<tr><th>Year</th><th>DBH</th><th>Biomass</th><th>Tree CO<sup>2</sup><th>Rel Tree CO<sup>2</sup></th><th>Replacement CO<sup>2</sup></th><th>Net CO<sup>2</sup></tr>";
    for (var year =0;year<Years;year++) {
        table+="<tr><td>"+year+"</td><td>"+Model.tree_pts[year].DBH.toFixed(1)+"</td><td>"+Model.tree_pts[year].biomass.toFixed(3)+"</td><td>"+Model.tree_pts[year].CO2.toFixed(3)+"</td><td>"+Model.tree_pts[year].rel_CO2.toFixed(3)+"</td><td>"+Model.rep_pts[year].toFixed(3)+"</td><td>"+Model.benefit_pts[year].toFixed(3)+"</td></tr>";
    };
    table +="</table>";
    $('#raw-data').html(table);
}

// SVG creation

function svg_line(x1,y1,x2,y2,style) {
    return "<line x1='"+x1+"' y1='"+y1+"' x2='"+x2+"' y2='"+y2+"' style='"+style+"'/>";
}

function svg_text(x,y,char,style) {
    return "<text x='"+x+"' y='"+y+"' style='"+style+"' transform='scale(1,-1) '>"+char+"</text>";
}

function svg_path(points,scale_x,scale_y,style) {
    if (points.length ==0)
      return "";
    var svg = "<path d='";
    var first = points[0];
    svg+= " M " + first[0]*scale_x+ " " + first[1]*scale_y;
    for (var i = 1;i <points.length;i++) {
         var p = points[i];
         svg += " L " + p[0]*scale_x+ "," + p[1]*scale_y;
    }
    svg += "' style='"+ style +"'/>";
    return svg;
}

function svg_sequence(points,scale_x,scale_y,style,start=0) {
    if (points.length ==0)
      return "";
    var svg = "<path d='";
    var first = points[0];
    svg+= " M " + start*scale_x + " " + first*scale_y;
    for (var i = 1;i <points.length;i++) {
         svg += " L " + (i+start)*scale_x+ "," + points[i]*scale_y;
    }
    svg += "' style='"+ style +"'/>";
    return svg;
}
function net_negative(pts,breakeven) {
     var npts=[];
     max = breakeven > pts.length  || breakeven == -1 ? pts.length : Math.floor(breakeven);
     for (var i=0;i<max;i++)
        npts.push([i,pts[i]]);
     if (breakeven != -1 && breakeven < pts.length) npts.push([breakeven,0]);
     return npts;
}

function net_positive(pts,breakeven) {
     var npts=[];
     if (breakeven != -1 && breakeven < pts.length) {
        npts.push([breakeven,0]); 
        first =Math.ceil(breakeven);
        for (var i=first;i<pts.length;i++)
        npts.push([i,pts[i]]);       
     }
      return npts;
}

function graph_svg(scale_x,scale_y,y_min,y_max) {
   line_width=1;
   tree_colour="blue"; 
   rep_colour="black";
   benefit_negative="red";
   benefit_positive="green";
   
// tree CO2 curve 
   var svg="";
   var line_style="fill: none; stroke:"+tree_colour+"; stroke-width:"+line_width+";  ";
   svg +=svg_sequence(select_sequence(Model.tree_pts,"rel_CO2"),scale_x,scale_y,line_style) ;   
   
// replacement biomass curve

   var line_style="fill: none; stroke:"+rep_colour+"; stroke-width:"+line_width+";  ";
   svg += svg_sequence(Model.rep_pts,scale_x,scale_y,line_style) ;

// benefit curve
    var red = net_negative(Model.benefit_pts,Model.breakeven);
//    console.log(Model.breakeven);
//   console.log(red);
    var line_style="fill: none; stroke:"+benefit_negative+"; stroke-width:"+line_width*4+"; ";
    svg+= svg_path(red,scale_x,scale_y,line_style) ;
    var green=  net_positive(Model.benefit_pts,Model.breakeven);
//    console.log(green);
    var line_style="fill: none; stroke:"+benefit_positive+"; stroke-width:"+line_width*2+"; ";
    svg+= svg_path(green,scale_x,scale_y,line_style) ;
/*     
   var line_style="fill: none; stroke:purple; stroke-width:3";
   if (breakeven != 0 ) svg+=svg_line(Model.breakeven*scale_x,-10,Model.breakeven*scale_x,10,line_style);
*/
// X axis
   var line_style="fill: none; stroke:black; stroke-width:"+line_width+"; ";
   var text_style="font-size: 12pt"
   svg +=svg_line(0,0,Years*scale_x,0,line_style);
   for(x=5;x<=Years;x+=5) {
        svg+= svg_line(x*scale_x,0,x*scale_x,-5,line_style);
        svg+= svg_text(x*scale_x-5,20,x,text_style);
   }
   
// Y axis
   svg += svg_line(0,y_min*scale_y,0, y_max*scale_y,line_style);
   for(y=y_min;y<=y_max;y+=1) {
        svg+=svg_line(0,y*scale_y,-5,y*scale_y,line_style);
        svg+=svg_text(-15,-y*scale_y,y,text_style);
    }  
   return svg; 
}

function small_graph_svg(scale_x,scale_y,y_min,y_max) {
   line_width=1;
   benefit_colour="red";
 
   var svg="";
// benefit curve
    var red = net_negative(Model.benefit_pts,Model.breakeven);
    var line_style="fill: none; stroke:"+benefit_negative+"; stroke-width:"+line_width*4+"; ";
    svg+= svg_path(red,scale_x,scale_y,line_style) ;
    var green=  net_positive(Model.benefit_pts,Model.breakeven);
    var line_style="fill: none; stroke:"+benefit_positive+"; stroke-width:"+line_width*2+"; ";
    svg+= svg_path(green,scale_x,scale_y,line_style) ;

// X axis
   var line_style="fill: none; stroke:black; stroke-width:"+line_width+"; ";
   var text_style="font-size: 12pt"
   svg +=svg_line(0,0,Years*scale_x,0,line_style);
   for(x=5;x<=Years;x+=5) {
        svg+= svg_line(x*scale_x,0,x*scale_x,-5,line_style);
        svg+= svg_text(x*scale_x-5,20,x,text_style);
   }
   
// Y axis
   svg += svg_line(0,y_min*scale_y,0, y_max*scale_y,line_style);
   for(y=y_min;y<=y_max;y+=1) {
        svg+=svg_line(0,y*scale_y,-5,y*scale_y,line_style);
        svg+=svg_text(-15,-y*scale_y,y,text_style);
    }  
   return svg; 
}

function create_graph() {
   padding=20;
   x_range = Years;
   y_max=8;
   y_min=-5;
   y_range= y_max - y_min ;
   width=700;
   height=500;
   $('#svgimage').attr("width",width);
   $('#svgimage').attr("height",height);
   scale_x = width / x_range;
   scale_y = height /y_range
   var svg = graph_svg(scale_x,scale_y,y_min,y_max);
   canvas=$('#canvas');
   canvas.empty();
   canvas.append(svg);
   transform = 'translate(30,' + height*0.6 +') scale(1,-1)';
//  console.log(transform);  
   canvas.attr("transform",   transform  );
// svg update trick to get it executed as well as added
   $("#svgframe").html($('#svgframe').html());  
}

function create_small_graph() {
   padding=20;
   x_range = Years;
   y_max=8;
   y_min=-5;
   y_range= y_max - y_min ;
   width=500;
   height=300;
   $('#svgimage-2').attr("width",width);
   $('#svgimage-2').attr("height",height);
   scale_x = width / x_range;
   scale_y = height /y_range
   var svg = small_graph_svg(scale_x,scale_y,y_min,y_max);
   canvas=$('#canvas-2');
   canvas.empty();
   canvas.append(svg);
   transform = 'translate(30,' + height*0.6 +') scale(1,-1)';
//  console.log(transform);  
   canvas.attr("transform",   transform  );
// svg update trick to get it executed as well as added
    $("#svgframe-2").html($('#svgframe-2').html());  
}

// visibility controls

function tab(n) {
  $('#tab'+n).show();
  $('#but'+n).css("background-color","lightgreen");
  for (var i=0;i<ntabs;i++)
     if (i != n) {
       $('#tab'+i).hide(); 
       $('#but'+i).css("background-color","white");        
     }
};

function hide_show(id) {
    div =$('#'+id);
    if (div.is(":visible"))
        div.hide();
    else div.show();
}

$(document).ready(function(){
     def_sliders();
     ntabs = $('div.tab').length;
     tab(initial_tab);
     set_scenario(0);
})