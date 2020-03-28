import module namespace tp-benefits = "http://kitwallace.co.uk/lib/tp-benefits" at "tp-benefits.xqm";
declare variable $local:info-icon := <img src="assets/Info_Symbol.png" width="10px"/>;
declare option exist:serialize "method=xhtml media-type=text/html";


declare function local:tooltip($text) {
     <span class="tooltip">{$local:info-icon}
           <span class="tooltiptext">{string($text)}</span>
     </span>
};

declare function local:slider-row($param, $i) {
                <tr>
                    <th width="170pt">
                         <span id="slidername{$i}"><b>{$param/name/string()}</b></span> 
                         {if ($param/title)
                          then 
                            local:tooltip($param/title)
                          else "&#160;"
                         }
                    </th>
                     <td width="100pt">
                        <input type="text" size="2" id="p-{$i}" onchange="refresh()"/>&#160;
                        {$param/unit/string()}
                    </td>
                    <td width="230pt">
                       <div class="slider" id="slider{$i}"/> 
                    </td>                 
                </tr>
};

let $ui-configuration := doc("ui-config.xml")/params
let $tab := request:get-parameter("tab",0)
let $scenarios := doc("scenarios.xml" )/scenarios
return 
  
<html>
    <head>
        <title>Tree CO2</title>
        <script src="https://code.jquery.com/jquery-1.12.4.js"/>
        <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"/>
        <script src="assets/jquery-touch.js"/>
        <link rel="stylesheet" type="text/css" href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css"/>
        <link rel="stylesheet" type="text/css" href="assets/ui-screen.css" media="screen"/>
        <link rel="stylesheet" type="text/css" href="assets/ui-mobile.css" media="mobile"/>
        <link rel="stylesheet" type="text/css"
            href="https://fonts.googleapis.com/css?family=Merriweather%20Sans"/>
        <link rel="stylesheet" type="text/css"
            href="https://fonts.googleapis.com/css?family=Gentium%20Book%20Basic"/>

        <script type="text/javascript" >
            var initial_tab = {$tab};
            var Sliders = [
            {string-join(
             for $param at $i in $ui-configuration/param
             return concat(" {id:'",$param/id,"',min:",$param/min,",max:",$param/max,
                 ",step:",($param/step,1)[1],"}"),
             ",&#10;")
            }
            ];
            var Scenarios = [
            {string-join(
             for $scenario in $scenarios/scenario
             return
              concat("{",
                string-join(
                  for $param in $scenario/*
                  let $id := name($param)
                  let $val := if ($param castable as xs:float)
                              then $param
                              else concat("'",$param,"'")
                  return concat($id,":",string($val)),
                 ","),
                "}"),
              ",&#10;") 
             }];
        </script>
        <script type="text/javascript" src='assets/interactive.js'/> 
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <link href="assets/navicon.png" rel="icon" sizes="128x128" />
        <link rel="shortcut icon" type="image/png" href="assets/navicon.png"/>
    </head>
    <body>
        <div><a target="_blank" href="https://bristoltreeforum.org/"><img src="assets/BTF128.png" width="40"/></a>
        <span style="font-size:20pt;"><a href="?">Tree CO<sup>2</sup></a></span>&#160;
            <span>
                <button  id="but0" onClick="tab(0)">Summary</button>
            </span>&#160;
            <span>
                <button  id="but1" onClick="tab(1)">Details</button>
            </span>&#160;
           <span>
                <button id="but2" onClick="tab(2)">About</button>
            </span>&#160;

        </div>
         <div id="tab0"  class="tab">
           <div style="width:40%;padding-top:12pt;">This calculator predicts the impact on CO<sup>2</sup> sequestration of felling a mature tree and replacing it with a number of new replacement trees. The <button onClick="tab(0)">Summary</button> page shows a summary of the selected scenario. 
           The <button onClick="tab(1)">Details</button> page shows full data and allows you to adjust the parameters of the model used in the prediction. The <button onClick="tab(1)">About</button> page explains the modeling and terms used.
           </div>

          <h4>Scenarios </h4>
             <ul>
                 {for $scenario at $i in $scenarios/scenario
                  return <li><button class="scenario" id="{concat('scenario',$i - 1)}" onClick="set_scenario({$i - 1})">{$scenario/title/string()}</button></li>
                 }
             </ul>
             <h4>Summary   <button onClick="tab(1)">Details</button></h4>
              <table id="summary">
              <tr><th>Tree DBH {local:tooltip("Diameter at Breast Height measured at 1.4 m above ground.")}</th><td><input type="text" id="summary-DBH" value="40" size="2" onChange="summary_refresh()"/><button id="refresh-summary" onClick="summary_refresh()">Change</button></td></tr>
              <tr><th>Tree age{local:tooltip("Calculated from the estimated size of annual growth rings - see About page.")}</th><td id="summary-age"/></tr>
              <tr><th>Number of replacements{local:tooltip("In Bristol, the number of replacement trees is determined by the Bristol Tree Replacement Standard - see About page.")}</th><td><input type="checkbox" id="summary_use_BTRS" checked="checked" onchange="summary_refresh()" >Use BTRS {$local:info-icon}</input><input type="text" id="summary-NRep"  size="2"/><button id="refresh-summary" onClick="summary_refresh()">Change</button></td></tr>
              <tr><th>Target Breakeven Year{local:tooltip("The number of replacement trees can be calculated so that the breakeven year is less than or equal to the target year.")}</th><td><input type="text" id="target-year" value="30" size="2" onChange="solve_breakeven()"/> <button id="solve_breakeven" onClick="solve_breakeven()">Compute No. of replacements needed.</button></td></tr>
              <tr><th>Breakeven year{local:tooltip("The year when the replacement trees balance the loss of the original tree.")}</th><td id="breakeven"/></tr>  
              <tr><th>Net CO<sup>2</sup> after felling {local:tooltip("The CO2 captured by the lost tree and returned to the atmosphere after felling.")}</th><td id="tree-CO2"/></tr>
              <tr><th>Net CO<sup>2</sup> in 2030{local:tooltip("Bristol aims to be Carbon neutral by 2030.")}</th><td id="CO2-2030"/></tr>
              <tr><th>Net CO<sup>2</sup> in 2050{local:tooltip("UK aims to be Carbon neutral by 2050.")}</th><td id="CO2-2050"/></tr>
<!--              <tr><th>Heat increase{local:tooltip("Cumulative excess CO2 in atmosphere to breakeven. Expressed in tonne-years until we are able to convert to a more meaningful measure of temperature increase.")}</th><td id="heat-increase"/></tr>
 -->              </table>
         <div style="page-break-before: always; position:absolute; left:45%; top:0;">
                <h3 style="text-align:center">Tonnes CO<sup>2</sup> by year</h3>
                <div style="text-align:center">
                   <span style="color:red; font-size:larger;font-weight:bold;">Net Loss </span>&#160;  <span style="color:green">Net Gain</span>&#160;             
                </div>
                <div id="svgframe-2" style="padding-top:10pt">               
                <svg xmlns="http://www.w3.org/2000/svg" id="svgimage-2" width="600" height="400">
                    <g id="canvas-2" transform="translate(50,20)"/>
                </svg>
                </div>
            </div>
         </div>
   
        <div id="tab1" class="tab">
           <h3>Detailed analysis : <span id="scenario" style="font-size:smaller"/></h3>
            <div>
               <table id="sliders">
               <tr><td colspan="3" style="font-size:14pt;padding-left:20pt;font-weight:bold">Lost Tree</td></tr>
                {for $param at $j in $ui-configuration/param[group="tree"]
                 let $i := $j - 1
                 return
                    local:slider-row($param, $i)
                }
               <tr><td colspan="3"><span style="font-size:12pt;padding-left:20pt;font-weight:bold">Replacements</span>
               Use BTRS {local:tooltip("In Bristol, the number of replacement trees is determined by the Bristol Tree Replacement Standard - see About page.")} <input type="checkbox" id="use_BTRS" checked="checked" onchange="refresh()" />
               Same Species {local:tooltip("If the replacement species are different from the tree species, uncheck this box and set the tree parameters below.")}  <input type="checkbox" id="same_species" checked="checked" onchange="refresh()"/>
               </td></tr>
                 {let $tp := count($ui-configuration/param[group="tree"])
                 for $param at $j in $ui-configuration/param[group="replacement"]
                 let $i := $j - 1 +$tp
                 return
                    local:slider-row($param, $i)
                }
            </table>
            </div>
            <div>
                <h3>Predicted values</h3>
                <div id="raw-data"/>
            </div>

             <div style="page-break-before: always; position:absolute; left:45%; top:0;">
                <h3 style="text-align:center">Tonnes CO<sup>2</sup> by year</h3>
                <div style="text-align:center">
                 <span style="color:red;font-size:larger;font-weight:bold;">Net Loss </span>&#160;
                 <span style="color:green">Net Gain </span>&#160;
                 <span style="color:blue">Lost tree</span>&#160;
                 <span style="color:black">Replacements</span>&#160;
                 Max years <input type="text" name="Years" id="Years" value="60" size="2" onchange="refresh()"/>
               
                </div>
                <div id="svgframe" style="padding-top:10pt"> 
                
                <svg xmlns="http://www.w3.org/2000/svg" id="svgimage" width="800" height="600">
                    <g id="canvas" transform="translate(50,20)"/>
                </svg>
                </div>
            </div>
            </div>
           
            <div id="tab2"  class="tab">
          <div>
         <h2>About</h2>
  <div>This model predicts the impact of felling a mature tree and replacing it with a number of new replacement trees. If selected, this number is determined by the Bristol Tree Replacement Standard (see below).  The interface allows the user to see the effect of changing any of a number of parameters, some of which describe the lost tree such as its diameter and lifespan, others describe the replacements. 
  In addition, the user can change the parameters of the growth model such as the rate of growth and the conversion from tree diameter to tree biomass.  Since these values are rather unknown, this allows the user to see how sensitive the prediction is to uncertainties in this model. 
  </div>
  <h3>Bristol Tree Replacement Standard (BTRS)</h3>
   <div>In Bristol, the number of trees planted to compensate for the loss of an existing trees depends upon the situation and the size of the lost tree.
   The <a target="_blank" class="external" href="https://bristoltreeforum.files.wordpress.com/2020/03/bristol-tree-replacement-standard-btrs.pdf">Bristol Tree Replacement Standard</a> applies to trees lost through development.  A tree covered by a TPO is replaced by a single tree but a BCC-managed tree in a street or park 
   is not replaced by the council and any replacement must be funded by citizens at a cost of £295.
  </div>
   <h4>BTRS table</h4> 
   <h4> <button onclick="hide_show('tab-BTRS')">Replacement trees</button></h4>
   <div id="tab-BTRS"  style="display:none">
     {tp-benefits:BTRS-table()}
   </div>
 <h3>DBH to Age table</h3>
  <div>DBH = Diameter at breast height - usually 1.4 metres from the base of the tree. Prediction of Age from DBH uses calibration data obtained from <a  href="https://www.forestresearch.gov.uk/documents/6765/FCIN012.pdf">Information Note FCIN12</a> "Estimating the Age of Large and Veteran Trees in Britain" 
  by John White from the Forestry Commission. In this model, the tree puts on rings of constant width up to the age of maturity, and then rings of constant area until senescence.
  </div>
  
  <h4><button onclick="hide_show('tab-age')">Species table</button></h4>
  <div id="tab-age" style="display:none">
     {tp-benefits:age-table()}
  </div>
  <h3>Age to DBH</h3>
    <div>The relationship from Age to DBH is the inverse of the DBH to Age relationship and uses the same growth model as in the White paper above.  This table shows the effect of varying the increase in tree-ring radius per annum, and the age of maturity on the estimated DBH at different ages: 
    </div>
    <h4><button onclick="hide_show('tab-radius')">Age Radius table</button></h4>
    <div id="tab-radius" style="display:none">
    <table class="sortable">
   <tr><th>Ring radius<br/>/year in mm</th><th>Age at Maturity</th><th>DBH cm<br/>5 years</th><th>DBH cm<br/>25 years</th><th>DBH cm<br/>100 years</th></tr>
    {for $radius in 2 to 7
     for $age-at-maturity in (25,50,100)
     return
     <tr><td>{$radius}</td><td>{$age-at-maturity}</td>
     <td>{round-half-to-even(tp-benefits:DBH-estimate($radius,$age-at-maturity,5),2)}</td>
     <td>{round-half-to-even(tp-benefits:DBH-estimate($radius,$age-at-maturity,25),2)}</td>
     <td>{round-half-to-even(tp-benefits:DBH-estimate($radius,$age-at-maturity,100),2)}</td>
     </tr>
   }
   </table>
   </div>
   <h3>Lifespan</h3>
   <div>Trees have lifespans which depend on a number of factors: species, situation, climate and diseases. Data on the expected lifespan of tree species is sparse and for urban trees even sparser. The table below shows some typical values. 
   To compute the effect of limited lifespan on both the lost tree and the replacement trees, this age is used to compute the mortality of the tree, based on the assumption that mortality is log-linear and that the lifespan represents the time after which only 10% will be alive. No adjustment is yet made 
   location. Mortality of urban trees, especially in the early, vulnerable years is quite high as the <a target="_blank" class="external" href="https://www.fs.fed.us/nrs/pubs/jrnl/2014/nrs_2014_roman_001.pdf">paper by Lara Roman </a> show, where mortality is estimated to be between 3.5 and 5% / annum. 
   </div>
   <h4><button onclick="hide_show('tab-tree-ages')">Lifespan of tree species</button></h4>
   <div id="tab-tree-ages" style="display:none">
   This table shows data from <a href="https://www.hellis.biz/advice-centre/living-with-trees/how-long-do-trees-live-in-the-uk/">Hellis</a> . 
   <table class="sortable">
   <tr><th>Species</th><th>Common name</th><th>Lifespan</th><th>Source</th></tr>
   {for $species in $tp-benefits:lifespans/species
    order by $species/latin
    return 
       <tr>
         <td>{$species/latin/string()}</td>
         <td>{$species/common/string()}</td>
         <td>{$species/age/string()}</td>
         <td>{$species/source/string()}</td>
       </tr>
   }
   </table>
 
 
   </div>
 
   <h3>DBH to Biomass</h3>
   <div>DBH to Biomass is computed with the relation ln(Biomass) = a + b* ln(DBH) with the coefficients taken from a number of sources.  
   </div>
    <h4><button onclick="hide_show('tab-coefficients')">Species coefficients</button></h4>
    <div id="tab-coefficients" style="display:none">
    <div>spg* is Specific Gravity</div>
    <table class="sortable">
   <tr><th>Species</th><th>a</th><th>b</th><th>Biomass<br/>5cm kg</th><th>Biomass<br/>25cm kg</th><th>Biomass<br/>100cm kg</th><th>Source</th></tr>
   {for $formula at $i in $tp-benefits:biomass-formula
    order by $formula/Species
    return 
       <tr><td>{$formula/Species/string()}</td><td>{$formula/a/string()}</td><td>{$formula/b/string()}</td>
       <td>{round(tp-benefits:dbh-to-biomass(5,$formula/a,$formula/b))} </td>
       <td>{round(tp-benefits:dbh-to-biomass(25,$formula/a,$formula/b))} </td>
       <td>{round(tp-benefits:dbh-to-biomass(100,$formula/a,$formula/b))} </td>
       <td>{$formula/source/string()}</td>
        </tr>
   }
   </table>
    <h4>Reference</h4>
   <ul>
   <li>janowiack : see <a target="_blank" class="external" href="https://serc.carleton.edu/eslabs/carbon/1b.html">Carbon Storage in Local Trees</a> which references the coefficientsano</li>
   <li>chojnacky <a target="_blank" class="external" href="https://www.fs.fed.us/nrs/pubs/jrnl/2014/nrs_2014_chojnacky_001.pdf">Updated generalized biomass equations for North American tree species</a> by Chojnacky et al (2013) </li>
   <li>forrester : <a target="_blank" href="https://www.researchgate.net/publication/316555199_Generalized_biomass_and_leaf_area_allometric_equations_for_European_tree_species_incorporating_stand_structure_tree_age_and_climate">Forrester et al (2017)</a></li>
   </ul>
    </div>
   <h3>Biomass to CO<sup>2</sup></h3>
    <div>Carbon is assumed to account for 50% of the mass of the tree although this is an upper limit. Seqestered Carbon is typically reported in CO<sup>2</sup> equivalent. Using the atomic weights of Carbon (12) and Oxygen(16) the conversion factor from Carbon to CO<sup>2</sup> is 12+2*16 / 12 =3.67.
   </div>
 
   <h3>Decay of lost tree</h3>
   <div>The CO<sup>2</sup> released back depends on the method of disposal. To support the eco-system, it is best that the tree decays in situ although this releases the stored carbon back to the environment, albeit slowly.
   It is assumed that the tree will decay steadily over 15 years.
   Much better for CO<sup>2</sup> retention would be to convert the tree into timber and use for construction and furniture, although the whole tree cannot be used this way. Timber still decays however. Softwoods used for paper and cardboard will decay in a few years. If used for fencing and pallets it can be assumed to decay in 10-15 years whereas hardwoods or wood used in construction would last much longer. If the tree is chipped and used as fuel in a biomass boiler, such as powers the BCC Blaise Nursery, then the whole amount of CO<sup>2</sup> is put back into the atmosphere very quickly. Set the years to 1 to simulate this situation.
   </div>
<!--
<h3>Monetary benefits</h3>
    <div>The prediction of environmental impacts from only an estimate of the tree canopy area uses US-based factors so is not calibrated for UK conditions. In that context, there is considerable uncertainly in extrapolating the data to the UK.  The factors are shown below and convert m<sup>2</sup> of tree canopy to pollutant captured or produced. The computed values derived from them must be treated with great scepticism because of this.
               </div>
               <div>Estimates of the monetary benefits of those impacts is also subject to debate.  The values shown below are based on those suggested by <a href="https://www.forestresearch.gov.uk/research/i-tree-eco/i-tree-resources/reporting-an-i-tree-eco-project/">Forestry Research</a> which uses figures from the UK government <a href="https://www.gov.uk/guidance/air-quality-economic-analysis">Air Quality: economic analysis</a>. The figures have wide ranges of sensitivity.
               </div>
         <h4> <button onclick="hide_show('tab-benefits')">Conversion factors and benefit values used</button></h4>
        <div id="tab-benefits"  style="display:none">
                <table> 
                     <tr><th>Component</th><th>description</th><th>kg/m<sup>2</sup>/yr</th><th>£ per tonne</th></tr>
                     {for $benefit in $tp-benefits:benefit-factors/benefit
                     let $heading := util:parse(concat("<span>",$benefit/html,"</span>"))
                     return 
                          <tr><th>{$heading}</th><td>{$benefit/name}</td><td>{$benefit/factor}</td><td>{$benefit/pounds}</td></tr>
                     }
                </table>
         </div>
 -->
   <hr/>
   <div>A <a target="_blank" class="external" href="https://bristoltrees.space/">Trees of Bristol</a> production for <a target="_blank" href="https://bristoltreeforum.org/">Bristol Tree Forum</a>. 
   Code and Issues on <a target="_blank" class="external"  href="https://github.com/KitWallace/TreeCO2">Github</a>. 
    </div>
   <div>See also a related project to explore the relationship between <a href="dbh-canopy-analysis.xq">DBH and canopy area</a></div>

    <div>20 March 2020</div>
   </div>
  </div>
    </body>
</html>
