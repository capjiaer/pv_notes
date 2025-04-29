Perc 有四种check
TOPO
查看是否存在对应的ESD 保护电路
1：比如查到VDD1_VSS1之间的通路，则需要检查其中是否存在power clamp
2：查看VSS/VSS1 之间有没有B2B 
3：查看VDD/VDD1之间是否有 保护电阻或者 level shifter

LDL
1：一些特定的结构需要保证其外面有P/N ring
2：对应的PNring有没有接到VDD/VSS
P2P：
抓出的TOPO 要检查其R
CD：
检查其线路中有没有可能导致其局部电流密度过大
Power switch 用于低功耗设计，关闭非alwayson 区域
