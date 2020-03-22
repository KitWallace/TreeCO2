module namespace tpb = "http://kitwallace.co.uk/lib/tp-benefits";
declare variable $tpb:base := "/db/apps/trees/tree-benefits/";
declare variable $tpb:age-estimates:= doc("age-estimate.xml")/*;
declare variable $tpb:dbh-biomass:= doc("dbh-biomass.xml")/*;
declare variable $tpb:dbh-canopy:= doc("dbh-canopy.xml")/*;
declare variable $tpb:benefit-factors:= doc("benefit-factors.xml")/*;
declare variable $tpb:BTRS := doc("BTRS.xml")/BTRS;
declare variable $tpb:biomass-formula:= 
  for $f in collection(concat($tpb:base,"biomass-formula"))//formula
  order by $f/Species
  return $f;
declare variable $tpb:canopy-formula:= 
   for $f in collection(concat($tpb:base,"canopy-formula"))//formula
   order by $f/Species
  return $f;
declare variable $tpb:lifespans:= doc("tree-ages.xml")/*;
declare variable $tpb:C-to-CO2 :=  (32+12) div 12;
declare variable $tpb:C-to-O2 :=  32 div 12;
declare variable $tpb:hectares-to-m2 := 10000;
declare variable $tpb:tonnes-to-kg := 1000;
declare variable $tpb:biomass-to-C := 0.5;
declare variable $tpb:cavat-unit-value := 15.88;
declare variable $tpb:cavat-CTI-factor := 1.5;
declare variable $tpb:cavat-functional-factor := 0.75;
declare variable $tpb:cavat-life-factor := 0.95;

declare function tpb:canopy-radius($width) {
       if ($width castable as xs:double)
       then number($width) div 2
       else let $ws := tokenize($width,"\s*,\s*")
            return sum(for $w in $ws where $w castable as xs:double return number($w)) div 4
};
            
declare function tpb:dbh-to-biomass($dbh,$formula) {
   math:exp($formula/a + $formula/b * math:log($dbh))
};

declare function tpb:dbh-to-biomass($dbh,$a,$b) {
   math:exp($a + $b * math:log($dbh))
};

declare function tpb:dbh-to-radius($dbh,$formula) {
   math:exp($formula/a + $formula/b * math:log($dbh)) 
};

declare function tpb:dbh-to-radius($dbh,$a,$b) {
   math:exp($a + $b * math:log($dbh)) 
};

declare function tpb:radius-to-canopy($radius) {
    math:pi() * $radius*$radius
};

declare function tpb:dbh-to-canopy($dbh,$formula) {
   let $radius := tpb:dbh-to-radius($dbh,$formula) 
   return math:pi() * $radius*$radius
};

declare function tpb:dbh-to-canopy($dbh,$a,$b) {
   let $radius := tpb:dbh-to-radius($dbh,$a,$b)
   return math:pi() * $radius*$radius
};

declare function tpb:dbh-to-rpa-canopy($dbh) {
    let $radius := 12 *  $dbh div 100
    return math:pi() * $radius * $radius
};

declare function tpb:biomass-to-CO2($biomass) {
    $biomass * $tpb:biomass-to-C * $tpb:C-to-CO2
};

declare function tpb:biomass-to-O2($biomass) {
    $biomass * $tpb:biomass-to-C * $tpb:C-to-O2
};

declare function tpb:dbh-to-cavat-value($dbh) {
  let $r := $dbh div 2
  return round($tpb:cavat-unit-value * math:pi() * $r * $r *$tpb:cavat-CTI-factor * $tpb:cavat-functional-factor * $tpb:cavat-life-factor)
};

declare function tpb:age-table() {
  element table {
     element tr {
       element th {"latin"},
       element th {"common"},
       for $site in $tpb:age-estimates/sites/site
       return
          element th {attribute style {"text-align:center"},attribute title {$site/description},$site/name}
     },
     for $species in $tpb:age-estimates/species
     return 
        element tr {
           element th {$species/latin/string()},
           element td {$species/common/string()},
           
         for $site in $tpb:age-estimates/sites/site
         let $rate := $species/rate[site=$site/name]
         return
           element td { attribute style {"text-align:center"},
                   if ($rate) then concat($rate/age-at-maturity,"/",$rate/ring-width) else ""
                   }
        }  
  }
};

declare function tpb:tree-rate($latin,$site) {
  let $rate := $tpb:age-estimates/species[latin=$latin]/rate[site=$site]
  return
  if ($rate) 
  then $rate 
  else $tpb:age-estimates/species[latin=$latin]/rate[site="Average site"]
};

declare function tpb:age-estimates($latin,$dbh) {
   let $conditions := $tpb:age-estimates/species[latin=$latin]
   let $rbh:= ($girth div math:pi() div 2) * 10
   return 
     element estimates {
       element dbh {$rbh * 2},
       for $rate in $conditions/rate
       let $core-age := $rate/age-at-maturity
       let $core-radius := round($rate/age-at-maturity * $rate/ring-width )
       return 
          if ($rbh <= $core-radius)
          then element estimate{  $rate/site, element stage {"core development"}, element age {round($rbh div $rate/ring-width )}, element rbh {$rbh}, element core-radius {$core-radius}}
          else  let $core-radius-1 := $core-radius - $rate/ring-width
                let $core-area := $core-radius * $core-radius * math:pi()
                let $core-area-1 := $core-radius-1 * $core-radius-1 * math:pi()
                let $CAI := $core-area - $core-area-1
                let $current-area := $rbh * $rbh * math:pi()
                let $growth-area := $current-area - $core-area
                let $growth-age:= $growth-area div $CAI
                return element estimate { $rate/site, element stage {"maturity"}, element age {round($core-age + $growth-age)}, element core-radius {$core-radius}}
      }
};

declare function tpb:age-estimate($ring-width,$age-at-maturity,$dbh) {
   let $rbh:= ($dbh div 2) * 10
   let $core-age := $age-at-maturity
   let $core-radius := round($age-at-maturity * $ring-width )
       return 
          if ($rbh <= $core-radius)
          then round($rbh div $ring-width )
          else  let $core-radius-1 := $core-radius - $ring-width
                let $core-area := $core-radius * $core-radius * math:pi()
                let $core-area-1 := $core-radius-1 * $core-radius-1 * math:pi()
                let $CAI := $core-area - $core-area-1
                let $current-area := $rbh * $rbh * math:pi()
                let $growth-area := $current-area - $core-area
                let $growth-age:= $growth-area div $CAI
                return round($core-age + $growth-age)
};

declare function tpb:age-estimate($rate,$dbh) {
   tpb:age-estimate($rate/ring-width,$rate/age-at-maturity,$dbh)
};

declare function tpb:DBH-estimate($ring-width,$age-at-maturity,$age) {
let $dbh := 
    if ($age <= $age-at-maturity)
    then 2 * $age*$ring-width div 10  (: mm to cm :)
    else 
       let $core-radius := $age-at-maturity * $ring-width
       let $core-radius-1 := $core-radius - $ring-width
       let $core-area := $core-radius * $core-radius * math:pi()
       let $core-area-1 := $core-radius-1 * $core-radius-1 * math:pi()
       let $CAI := $core-area - $core-area-1
       let $CAI-growth := $CAI*($age - $age-at-maturity) 
       let $total-radius := math:sqrt(($core-area + $CAI-growth) div math:pi())
       return 2 * $total-radius div 10
  return $dbh
};

declare function tpb:DBH-estimate($rate,$age) {
   tpb:DBH-estimate($rate/ring-width,$rate/age-at-maturity,$age)
};
declare function tpb:BTRS-table() {
   let $tab := $tpb:BTRS
   return
     <table border="1">
     <tr><th>DBH <br/>cm</th>
     <th>Number of<br/>Replacement Trees</th></tr>
     <tr><td style="text-align:center">Less than 15</td><td style="text-align:center">0 - 1</td></tr>
     {for $band in $tab/band[position() > 1]
     return <tr><td style="text-align:center">{$band/@lower/string()} - 
     {if ($band/@upper = 9999) then "" else concat(" less than ",$band/@upper)} </td><td  style="text-align:center">{$band/@trees/string()}</td></tr>
     }
     </table>
};
