topic_map(){
  map_f=$1
  val=`awk -v max=0 '{if($4>max){max=$4;k=$3}}END{print max" ("k")"}' $map_f`
  echo $val
}

combine_w(){
  map_f=$1
  val=`awk -v max=0 '{if($3>max){max=$3;k=$2}}END{print max" ("k")"}' $map_f`
  echo $val
}

function gen_report(){

  dataset=$1
  lang=$2
  system1=tm
  system2=bm25
  qtype1=title
  qtype2=all

  map11=`topic_map results/$dataset/$lang/$system1.title.map`
  map12=`topic_map results/$dataset/$lang/$system1.all.map`

  map21=`topic_map results/$dataset/$lang/$system2.title.map`
  map22=`topic_map results/$dataset/$lang/$system2.all.map`

  wmap1=`combine_w results/$dataset/$lang/combine.title.map`
  wmap2=`combine_w results/$dataset/$lang/combine.all.map`

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
  | System | QueryType |  MAP   |
  |--------|-----------|--------|
  | combined | $qtype1 |  $wmap1 |
  | combined | $qtype2 |  $wmap2 |
  """
  mkdir -p reports/$dataset
  printf "$report" > reports/$dataset/$lang.txt
  echo "saved to reports/$dataset/$lang.txt"

}

gen_report $1 $2
