function gen_report(){

  dataset=$1
  lang=$2
  system1=tm
  system2=bm25
  qtype1=title
  qtype2=all

  map11=`awk -v max=0 '{if($4>max){max=$4;k=$3}}END{print k" "max}' results/$dataset/$lang/tm.title.map  | awk '{print $2}'` 
  map12=`awk -v max=0 '{if($4>max){max=$4;k=$3}}END{print k" "max}' results/$dataset/$lang/tm.all.map  | awk '{print $2}'`
  k1=`awk -v max=0 '{if($4>max){max=$4;k=$3}}END{print k" "max}' results/$dataset/$lang/tm.title.map  | awk '{print $1}'`
  k2=`awk -v max=0 '{if($4>max){max=$4;k=$3}}END{print k" "max}' results/$dataset/$lang/tm.all.map  | awk '{print $2}'`
 
  map21=`awk -v max=0 '{if($4>max){max=$4;k=$3}}END{print k" "max}' results/$dataset/$lang/bm25.title.map  | awk '{print $2}'`
  map22=`awk -v max=0 '{if($4>max){max=$4;k=$3}}END{print k" "max}' results/$dataset/$lang/bm25.all.map  | awk '{print $2}'` 

  wmap1=`awk -v max=0 '{if($3>max){max=$3;k=$2}}END{print k" "max}' results/$dataset/$lang/combine.title.map | awk '{print $2}'`
  weight1=`awk -v max=0 '{if($3>max){max=$3;k=$2}}END{print k" "max}' results/$dataset/$lang/combine.title.map | awk '{print $1}'`

  wmap2=`awk -v max=0 '{if($3>max){max=$3;k=$2}}END{print k" "max}' results/$dataset/$lang/combine.all.map | awk '{print $2}'`
  weight2=`awk -v max=0 '{if($3>max){max=$3;k=$2}}END{print k" "max}' results/$dataset/$lang/combine.all.map | awk '{print $1}'`
  

  report="""
  ### Dataset:$dataset Lang:$lang
  
  #### Indiv Systems
  | System | QueryType |  MAP   |
  |--------|-----------|--------|
  | $system1 | $qtype1 | $map11 |
  | $system1 | $qtype2 | $map12 |
  | $system2 | $qtype1 | $map21 |
  | $system2 | $qtype2 | $map22 |

  #### Combined Systems
  | System | QueryType | IntpWeight |  MAP   |
  |--------|-----------|------------|--------|
  | combined | $qtype1 | $weight1 | $wmap1 |
  | combined | $qtype2 | $weight2 | $wmap2 |
  """
  mkdir -p reports/$dataset
  printf "$report" > reports/$dataset/$lang.txt
  echo "saved to reports/$dataset/$lang.txt"

}

gen_report $1 $2
