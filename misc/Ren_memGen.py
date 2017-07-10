#!/usr/bin/python3
#Generate verilog implementation of memory stage in SPN 
#Author: Ren Chen
#Date: Aug/19/2016

import getopt
import sys
import copy
import math

###A list port names or name prefix
addrRomNamePre = "addr_rom_"
addrRomCtrlModuleName = "addr_rom_ctrl_"
memStageName = "mem_stage_dp"
inDataNamePre = "in_data_"
outDataNamePre = "out_data_"
wireInName = "wire_in"
wireOutName = "wire_out"
switch2x2Name = "switch_2_2"
inStartPortName = "in_start"
outStartPortName = "out_start"

#Get arguments
def getArgs():
    args = sys.argv[1:]
    inputSize = args[0]
    stride = args[1]
    dp = args[2]  ##dp: data parallelism
    return inputSize,stride,dp


#Generate multi-port names
def genMultiPortName(fileName, numPorts, namePre, addTabs):
    with open(fileName, 'a') as wrFile:
        for i in range(0, numPorts):
            wrFile.write(namePre)
            #wrFile.write("_")
            wrFile.write(str(i))
            if(i == numPorts - 1):
                wrFile.write("")
            else:
                wrFile.write(",\n")
                if(addTabs):
                    wrFile.write("      ")
            

#Get output idx after stride permutation
def mapStridePer(inSize, inIdx, stride):
    outIdx = (int)(inIdx/stride) + (int)(inIdx % stride) * (int)(inSize/stride)
    return outIdx


##Generate rom memory for updating memory address
def genAddrRom(fileName, dp, sizeN, addrVec, memIdx):
    vecSize = len(addrVec)  ##vecSize = inpnut size / dp

    romAddrWidth = int(math.ceil(math.log(vecSize, 2.0)))
    dataWidth = romAddrWidth

    #Gen connection module
    with open(fileName, 'a') as wrFile:
        wrFile.write("\n")                    
        wrFile.write("module  "+addrRomNamePre+"dp")
        wrFile.write(str(dp))
        wrFile.write("_mem")
        wrFile.write(str(memIdx))
        wrFile.write("(\n")
        wrFile.write("en,                              \n")
        wrFile.write("clk,                             \n")
        wrFile.write("rst,                             \n")
        wrFile.write("addr,                            \n")
        wrFile.write("data                             \n")
        wrFile.write(");                               \n  ")
        #wrFile.write("parameter DATA_WIDTH = ")
        #wrFile.write(str(dataWidth))
        #wrFile.write(";                                \n  ")       
        wrFile.write("input en, clk, rst;                   \n  ")
        wrFile.write("input ["+str(romAddrWidth-1)+":0] addr;                        \n  ")
        wrFile.write("output reg ["+str(dataWidth-1)+":0] data;        \n  ")

    ##Wires
    with open(fileName, 'a') as wrFile:
        wrFile.write("\n  ")
        if(vecSize * dataWidth >= 256 * 16):
            wrFile.write("// synthesis attribute rom_style of data is \"block\" \n  ")
        else:
            wrFile.write("// synthesis attribute rom_style of data is \"distributed\" \n  ")
        wrFile.write("\n  ")
        #Update ctrl_out cycle by cycle
        wrFile.write("always@(posedge clk)             \n  ")
        wrFile.write("begin                            \n    ")
        wrFile.write("if(rst) begin                    \n      ")
        wrFile.write("data <= "+str(dataWidth)+"'b0;    \n      ")
        wrFile.write("end\n    ")
        wrFile.write("else begin                        \n      ")
        wrFile.write("if (en)                           \n        ")
        wrFile.write("case(addr)                        \n          ")
        for i in range(0, vecSize):
            tmpStr = bin(int(i))[2:].zfill(romAddrWidth)
            #tmpDataStr = (convVecToBinStr(addrVec[i]))
            tmpDataStr = bin(addrVec[i])[2:].zfill(dataWidth)
            wrFile.write(str(romAddrWidth)+"'b"+tmpStr+": data <= "+str(dataWidth)+"'b"+tmpDataStr+"; \n          ")
        wrFile.write("default: data <= "+str(dataWidth)+"'b0"+"; \n        ")
        wrFile.write("endcase\n    ")
        wrFile.write("end\n  ")
        wrFile.write("end                              \n")

        wrFile.write("\n")
        wrFile.write("endmodule                        \n\n")  


    return addrRomNamePre+"dp"+ str(dp)+ "_mem"+ str(memIdx)


##Generate control module for addr rom
def genAddrGen(fileName, dp, sizeN, addrVec):
    ##vecSize = x * sizeN/dp
    romAddrWidth = []
    for i in range(0,dp):
        vecSize = len(addrVec[i])
        romAddrWidth.append( int(math.ceil(math.log(vecSize, 2.0))) )

    sameSizeMap = {}
    count_tmp = 0
    for i in range(0, dp):
        if romAddrWidth[i] not in sameSizeMap.keys() :
            sameSizeMap[romAddrWidth[i]] = count_tmp
            count_tmp = count_tmp + 1 

    numWireGroup = len(sameSizeMap)
    wireGroupIdx = []
    for i in range(0, dp):
        wireGroupIdx.append(sameSizeMap[romAddrWidth[i]])

    ##ramSize = sizeN/dp
    ramSize = sizeN/dp
    addrRamWidth = int(math.ceil(math.log(ramSize, 2.0)))

    addrRomNames = []
    for memIdx in range(0, dp):
        addrRomNames.append(genAddrRom(fileName, dp, sizeN, addrVec[memIdx], memIdx))

    #Gen connection module
    with open(fileName, 'a') as wrFile:
        wrFile.write("\n")                    
        wrFile.write("module  "+addrRomCtrlModuleName+"dp")
        wrFile.write(str(dp))
        #wrFile.write("_")
        #wrFile.write(str(memIdx))
        wrFile.write("(\n")
        wrFile.write(inStartPortName+",                          \n")
        wrFile.write("wen_out,                         \n")
        wrFile.write("out_start,                         \n")
        for i in range(0,dp):
            wrFile.write("rom_out_"+str(i)+",                         \n")
        wrFile.write("clk,                             \n")
        wrFile.write("rst                              \n")
        wrFile.write(");                               \n  ")
        #wrFile.write("parameter DATA_WIDTH = ")
        #wrFile.write(str(dataWidth))
        #wrFile.write(";                                \n  ")       
        wrFile.write("input "+inStartPortName+", clk, rst;                   \n  ")
        for i in range(0,dp):
            wrFile.write("output ["+str(romAddrWidth[i]-1)+":0] rom_out_"+str(i)+";            \n  ")
        wrFile.write("output wen_out;                                        \n  ")
        wrFile.write("\n  ")
        for i in range(0,numWireGroup):
            wrFile.write("reg ["+str(sameSizeMap.keys()[i]-1)+":0] rom_addr_"+str(i)+";        \n  ")
        wrFile.write("reg addr_updating;        \n  ")
        wrFile.write("\n  ")
        for i in range(0,dp):
            wrFile.write(addrRomNames[i] +  " addr_rom_inst_" +  str(i) + "(.en(1'b1),.clk(clk),.rst(rst),"
                         + ".addr(rom_addr_"+str(sameSizeMap[romAddrWidth[i]])+"),.data(rom_out_"+str(i)+")); \n  ")

    ##Wires
    with open(fileName, 'a') as wrFile:
        wrFile.write("\n  ")
        wrFile.write("assign wen_out = addr_updating;        \n  ")
        wrFile.write("assign out_start = (rom_addr_0["+str(addrRamWidth-1)+":0] == "+str(ramSize-1)+"); \n"  ) 
        wrFile.write("\n  ")
        #Update ctrl_out cycle by cycle
        wrFile.write("always@(posedge clk)             \n  ")
        wrFile.write("begin                            \n    ")
        wrFile.write("if(rst) begin                    \n      ")
        for i in range(0, numWireGroup):
            wrFile.write("rom_addr_"+str(i)+" <= "+str(sameSizeMap.keys()[i])+"'b0;    \n      ")
        wrFile.write("addr_updating <= 1'b0;            \n      ")
        wrFile.write("end\n    ")
        wrFile.write("else begin                        \n      ")
        ##Make sure in_start has been registered
        wrFile.write("if (addr_updating || "+inStartPortName+" == 1'b1)  begin              \n        ")
        for i in range(0, numWireGroup):    
            wrFile.write("rom_addr_"+str(i)+" <= rom_addr_"+str(i)+" + 1;    \n        ")
        wrFile.write("end\n      ")
        ##addrRomWidth = x * addrRamWidth
        wrFile.write("if (rom_addr_0["+str(addrRamWidth-1)+":0] == "+str(ramSize-1)+") begin  \n        ")
        wrFile.write("addr_updating <= 1'b0;                 \n        ")
        for i in range(0, numWireGroup):
            wrFile.write("rom_addr_"+str(i)+" <= "+str(sameSizeMap.keys()[i])+"'b0;    \n        ")
        wrFile.write("end\n      ")
        wrFile.write("if ("+inStartPortName+") begin                     \n        " )
        wrFile.write("addr_updating <= 1'b1;                 \n        ")
        #wrFile.write("addr <= "+str(addrRomWidth)+"'b0;         \n      ")
        wrFile.write("end                                    \n    ")
        wrFile.write("end\n  ")
        wrFile.write("end                              \n")

        wrFile.write("\n")
        wrFile.write("endmodule                        \n\n")    

    return addrRomCtrlModuleName+"dp"+str(dp)


def convVecToBinStr(vecIn):
    size = len(vecIn)
    tmpStr = ""
    ##reverse the order
    for i in range(size-1, -1, -1):
        tmpStr += str(vecIn[i])
    return tmpStr


##Generate memory blocks in the middle stage
##SP: single port RAM
def genDataSPRam(fileName, dp, sizeN, dataWidth, ramStyle):
    memSize = sizeN / dp
    addrWidth = int(math.ceil(math.log(memSize, 2.0)))

    #Gen connection module
    with open(fileName, 'a') as wrFile:
        wrFile.write("\n")                    
        wrFile.write("module  "+ramStyle)
        wrFile.write("(\n")
        wrFile.write("wen,                              \n")
        if(ramStyle == "block_ram_sp"):
            wrFile.write("en,                              \n")
        wrFile.write("clk,                             \n")
        wrFile.write("addr,                            \n")
        wrFile.write("din,                            \n")
        wrFile.write("dout                             \n")
        wrFile.write(");                               \n  ")
        wrFile.write("parameter DATA_WIDTH = ")
        wrFile.write(str(dataWidth))
        wrFile.write(";                                \n  ")    
        wrFile.write("parameter ADDR_WIDTH = ")
        wrFile.write(str(addrWidth))
        wrFile.write(";                                \n  ")     
        wrFile.write("parameter RAM_SIZE = 1 << ADDR_WIDTH")
        wrFile.write(";                                \n  ")      
        wrFile.write("input wen, clk;                   \n  ")
        if(ramStyle == "block_ram_sp"):
            wrFile.write("input en;                              \n  ")
        wrFile.write("input [ADDR_WIDTH-1:0] addr;                        \n  ")
        wrFile.write("input [DATA_WIDTH-1:0] din;                        \n  ")
        wrFile.write("output [DATA_WIDTH-1:0] dout;        \n  ")

    ##Wires
    with open(fileName, 'a') as wrFile:
        wrFile.write("\n  ")
        wrFile.write("reg [DATA_WIDTH-1:0] ram[RAM_SIZE-1:0];        \n  ")
        wrFile.write("\n  ")
        #Update ctrl_out cycle by cycle
        wrFile.write("always@(posedge clk)             \n  ")
        wrFile.write("begin                            \n    ")
        if(ramStyle == "block_ram_sp"):
            wrFile.write("// synthesis attribute ram_style of ram is \"block\" \n  ")
            wrFile.write("if(en) begin                    \n      ")
            wrFile.write("if(wen)                         \n        ")
            wrFile.write("ram[addr] <= din ;              \n      ")
            wrFile.write("dout <= ram[addr];              \n  ")
            wrFile.write("end\n  ")
            wrFile.write("end                             \n  ")
        elif(ramStyle == "dist_ram_sp"):
            wrFile.write("// synthesis attribute ram_style of ram is \"distributed\" \n  ")
            wrFile.write("if(wen)                         \n      ")
            wrFile.write("ram[addr] <= din ;              \n  ")
            wrFile.write("end                             \n \n  ")
            wrFile.write("assign dout = ram[addr]         \n  ")


        wrFile.write("\n")
        wrFile.write("endmodule                        \n\n")


#Generate dual-port ram
def genDataDPRam(fileName, dp, sizeN, dataWidth, ramStyle):
    memSize = sizeN / dp
    addrWidth = int(math.ceil(math.log(memSize, 2.0)))

    #Gen connection module
    with open(fileName, 'a') as wrFile:
        wrFile.write("\n")                    
        wrFile.write("module  "+ramStyle)
        wrFile.write("(\n")
        wrFile.write("wen,                              \n")
        if(ramStyle == "block_ram_dp"):
            wrFile.write("en,                              \n")
        wrFile.write("clk,                             \n")
        wrFile.write("addr_r,                            \n")
        wrFile.write("addr_w,                            \n")
        wrFile.write("din,                            \n")
        wrFile.write("dout                             \n")
        wrFile.write(");                               \n  ")
        wrFile.write("parameter DATA_WIDTH = ")
        wrFile.write(str(dataWidth))
        wrFile.write(";                                \n  ")    
        wrFile.write("parameter ADDR_WIDTH = ")
        wrFile.write(str(addrWidth))
        wrFile.write(";                                \n  ")     
        wrFile.write("parameter RAM_SIZE = 1 << ADDR_WIDTH")
        wrFile.write(";                                \n  ")      
        wrFile.write("input wen, clk;                   \n  ")
        if(ramStyle == "block_ram_dp"):
            wrFile.write("input en;                              \n  ")
        wrFile.write("input [ADDR_WIDTH-1:0] addr_r;                        \n  ")
        wrFile.write("input [ADDR_WIDTH-1:0] addr_w;                        \n  ")
        wrFile.write("input [DATA_WIDTH-1:0] din;                        \n  ")
        wrFile.write("output [DATA_WIDTH-1:0] dout;        \n  ")

    ##Wires
    with open(fileName, 'a') as wrFile:
        wrFile.write("\n  ")
        wrFile.write("reg [DATA_WIDTH-1:0] ram[RAM_SIZE-1:0];        \n  ")
        wrFile.write("\n  ")
        #Update ctrl_out cycle by cycle
        wrFile.write("always@(posedge clk)             \n  ")
        wrFile.write("begin                            \n    ")
        if(ramStyle == "block_ram_dp"):
            wrFile.write("// synthesis attribute ram_style of ram is \"block\" \n  ")
            wrFile.write("if(en) begin                    \n      ")
            wrFile.write("if(wen)                         \n        ")
            wrFile.write("ram[addr_w] <= din ;              \n      ")
            wrFile.write("dout <= ram[addr_r];              \n  ")
            wrFile.write("end\n  ")
            wrFile.write("end                             \n  ")
        elif(ramStyle == "dist_ram_dp"):
            wrFile.write("// synthesis attribute ram_style of ram is \"distributed\" \n  ")
            wrFile.write("if(wen)                         \n      ")
            wrFile.write("ram[addr_w] <= din ;              \n  ")
            wrFile.write("end                             \n \n  ")
            wrFile.write("assign dout = ram[addr_r]         \n  ")


        wrFile.write("\n")
        wrFile.write("endmodule                        \n\n")


##Generate a counter
def genCounter(fileName, maxVal):
    dataWidth = int(math.ceil(math.log(maxVal, 2.0))) 


    with open(fileName, 'a') as wrFile:
        wrFile.write("\n")                    
        wrFile.write("module  "+"counter_"+str(maxVal))
        wrFile.write("(\n")
        wrFile.write(inStartPortName+",                         \n")
        wrFile.write("counter_out,                         \n")
        wrFile.write("clk,                             \n")
        wrFile.write("rst                              \n")
        wrFile.write(");                               \n  ")  
        wrFile.write("input clk, rst;                   \n  ")
        wrFile.write("output ["+str(dataWidth-1)+":0] counter_out;            \n  ")
        wrFile.write("\n  ")
        wrFile.write("reg ["+str(dataWidth-1)+":0] counter_r;        \n  ")
        wrFile.write("reg status_couting;        \n\n  ")
        wrFile.write("assign counter_out = counter_r;        \n  ")
        wrFile.write("\n  ")
        wrFile.write("always@(posedge clk)             \n  ")
        wrFile.write("begin                            \n    ")
        wrFile.write("if(rst) begin                    \n      ")
        wrFile.write("counter_r <= "+str(dataWidth)+"'b0;    \n      ")
        wrFile.write("status_couting <= 1'b0;            \n    ")
        wrFile.write("end\n    ")
        wrFile.write("else begin                        \n      ")
        ##Make sure in_start has been registered
        wrFile.write("if (status_couting == 1'b1)                \n        ")
        wrFile.write("counter_r <= counter_r + 1'b1;                   \n      ")
        ##addrRomWidth = x * addrRamWidth
        wrFile.write("if (counter_r["+str(dataWidth-1)+":0] == "+str(maxVal-1)+") begin  \n        ")
        wrFile.write("status_couting <= 1'b0;                 \n        ")
        wrFile.write("counter_r <= "+str(dataWidth)+"'b0;         \n      ")
        wrFile.write("end                                    \n      ")
        wrFile.write("if ("+inStartPortName+") begin                     \n        ")
        wrFile.write("status_couting <= 1'b1;                 \n      ")
        #wrFile.write("counter_r <= "+str(dataWidth)+"'b0;         \n      ")
        wrFile.write("end                                    \n    ")
        wrFile.write("end\n  ")
        wrFile.write("end                              \n")

        wrFile.write("\n")
        wrFile.write("endmodule                        \n\n")    

    return "counter"+str(maxVal)

def getPortStyle(dp, sizeN, addrVec):
    portStyle = []
    for vec in addrVec:
        if(len(vec) > sizeN/dp):
            portStyle.append("sp")
        else:
            portStyle.append("dp")
    return portStyle

##Generate memory stage
def genMemStage(fileName, dp, sizeN, dataWidth, addrVec, regOut):
    memSize = sizeN / dp
    addrWidth = int(math.ceil(math.log(memSize, 2.0))) 
    moduleName = ""
    portStyle = getPortStyle(dp, sizeN, addrVec)

    counterModuleName = genCounter(fileName, memSize)

    #addrGenModuleName = []
    #for memIdx in range(0, dp):
    addrGenModuleName = genAddrGen(fileName, dp, sizeN, addrVec)

    ##Generate address generator modules
    #for memIdx in range(0, dp):
    #    genAddrGen(fileName, dp, sizeN, addrVec[memIdx], memIdx)

    #Gen connection module
    with open(fileName, 'a') as wrFile:
        wrFile.write("\n")   
        moduleName = memStageName + str(dp) +  
        if(regOut):
            moduleName += "_r"     
        wrFile.write("module "+moduleName)
        wrFile.write("(\n")

    #Generate multiport names
    genMultiPortName(fileName, dp, inDataNamePre, False)
    with open(fileName, 'a') as wrFile:
        wrFile.write(",\n")
    #Generate multiport names
    genMultiPortName(fileName, dp, outDataNamePre, False)
    with open(fileName, 'a') as wrFile:
        wrFile.write(",\n")

    with open(fileName, 'a') as wrFile:
        wrFile.write(inStartPortName+",                        \n")
        wrFile.write(outStartPortName+",                       \n")
        #wrFile.write("ctrl,                            \n")
        for i in range(0,dp):
            wrFile.write(inDataNamePre+str(i)+",                       \n")
        or i in range(0,dp):
            wrFile.write(outDataNamePre+str(i)+",                       \n")
        wrFile.write("clk,                             \n")
        wrFile.write("rst                              \n")
        wrFile.write(");                               \n  ")
        wrFile.write("parameter DATA_WIDTH = ")
        wrFile.write(str(dataWidth))
        wrFile.write(";                                \n  ")       
        wrFile.write("input "+inStartPortName+", clk, rst;                   \n  ")
        #wrFile.write("input ["+str(dp/2)+"-1:0] ctrl;        \n  ")
        wrFile.write("input [DATA_WIDTH-1:0] ")

    ##input ports
    genMultiPortName(fileName, dp, inDataNamePre, True)
    with open(fileName, 'a') as wrFile:
        wrFile.write(";\n  ")

    with open(fileName, 'a') as wrFile:
        if(not regOut):
            wrFile.write("output [DATA_WIDTH-1:0] ")
        else:
            wrFile.write("output reg [DATA_WIDTH-1:0] ")

    ##output ports
    genMultiPortName(fileName, dp, outDataNamePre, True)

    with open(fileName, 'a') as wrFile:
        wrFile.write("\n  ")
        if(not regOut):
            wrFile.write("output "+outStartPortName+"; ")
        else:
            wrFile.write("output reg "+outStartPortName+"; ")
        wrFile.write("\n  ")

    ##Wires
    with open(fileName, 'a') as wrFile:
        wrFile.write("\n  ")
        wrFile.write("wire [DATA_WIDTH-1:0] "+wireInName+" ["+str(dp-1)+":0];              \n  ")
        wrFile.write("wire [DATA_WIDTH-1:0] "+wireOutName+" ["+str(dp-1)+":0];              \n  \n  ")
        wrFile.write("wire wen_wire;              \n  ")
        wrFile.write("wire out_start_wire;              \n  ")
        ##Connect wireIn with inData
        for i in range(0, dp):
            wrFile.write("assign "+wireInName+"["+str(i)+"] = "+inDataNamePre+str(i)+";    \n  ")
        wrFile.write("\n  ")

    with open(fileName, 'a') as wrFile:
        for i in range(0, dp):
            if(portStyle[i] == "sp"):
                wrFile.write("wire ["+str(addrWidth-1)+":0] addr_wire_"+str(i)+";        \n  ")
            elif(portStyle[i] == "dp"):
                wrFile.write("wire ["+str(addrWidth-1)+":0] addr_w_wire_"+str(i)+";        \n  ")
        if "dp" in portStyle:
            wrFile.write("wire ["+str(addrWidth-1)+":0] addr_r_wire_"+str(0)+";        \n\n  ")
            #wrFile.write("wire wen_wire_"+str(i)+";        \n\n  ")
            ##Generate counter module
            wrFile.write(counterModuleName+" counter_inst(")
            wrFile.write("."+inStartPortName+"("+inStartPortName+"), ")
            wrFile.write(".counter_out(addr_r_wire_0), ")
            wrFile.write(".clk(clk), .rst(rst));\n\n  ")


    with open(fileName, 'a') as wrFile:
        ##Gen several memory blocks
        ramStyle = ""
        if (((sizeN/dp) * dataWidth) >= 256*16):
            ramStyle = "block_ram_"
        else:
            ramStyle = "dist_ram_"
        ##ramStyle += portStyle 

        ##Generate ram address generator module
        wrFile.write(addrGenModuleName+" addr_gen_inst(")
        wrFile.write("."+inStartPortName+"("+inStartPortName+"), ")
        wrFile.write(".wen_out(wen_wire), ")
        wrFile.write(".out_start(out_start_wire), ")
        for i in range(0,dp):
            if(portStyle[i] == "sp"):
                wrFile.write(".rom_out_"+str(i)+"(addr_wire_"+str(i)+"), ")
            elif(portStyle[i] == "dp"):
                wrFile.write(".rom_out_"+str(i)+"(addr_w_wire_"+str(i)+"), ")
        wrFile.write(".clk(clk), .rst(rst));\n\n  ")

    ##Generate dp/2 addr generators
    with open(fileName, 'a') as wrFile:
        for i in range(0, dp):
            ramModuleName = ramStyle + portStyle[i]
            if(portStyle[i] == "sp"):
                ##Generate single-port memory blocks
                wrFile.write(ramModuleName+" ram_inst_"+str(i)+"#(")
                wrFile.write(".DATA_WIDTH("+str(dataWidth)+"), ")
                wrFile.write(".ADDR_WIDTH("+str(addrWidth)+")) \n        (")
                wrFile.write(".wen(wen_wire), ")
                if(ramModuleName == "block_ram_sp"):
                    wrFile.write(".en(1'b1), ")
                wrFile.write(".addr(addr_wire_"+str(i)+"), ")
                wrFile.write(".din("+wireInName+"["+str(i)+"]), ")
                wrFile.write(".dout("+wireOutName+"["+str(i)+"]), ")
                wrFile.write(".clk(clk), .rst(rst));\n\n  ")
                
            elif(portStyle[i] == "dp"):
                wrFile.write(ramModuleName+" ram_inst_"+str(i)+"#(")
                wrFile.write(".DATA_WIDTH("+str(dataWidth)+"), ")
                wrFile.write(".ADDR_WIDTH("+str(addrWidth)+")) \n        (")
                wrFile.write(".wen(wen_wire), ")
                if(ramModuleName == "block_ram_dp"):
                    wrFile.write(".en(1'b1), ")
                wrFile.write(".addr_r(addr_r_wire_"+str(0)+"), ")
                wrFile.write(".addr_w(addr_w_wire_"+str(i)+"), ")
                wrFile.write(".din("+wireInName+"["+str(i)+"]), ")
                wrFile.write(".dout("+wireOutName+"["+str(i)+"]), ")
                wrFile.write(".clk(clk), .rst(rst));\n\n  ")


        wrFile.write("\n  ")
        #Connect wireOut with OutData
        # wrFile.write("reg wen_out_r; \n\n  ")
        # wrFile.write("always@(posedge clk)             \n  ")
        # wrFile.write("begin                            \n    ")
        # wrFile.write("wen_out_r <=  wen_wire           \n  ")
        # wrFile.write("end                            \n\n  ")

        if(regOut):
            wrFile.write("always@(posedge clk)             \n  ")
            wrFile.write("begin                            \n    ")
            wrFile.write("if(rst) begin                    \n      ")
            for i in range(0, dp):
                wrFile.write(outDataNamePre+str(i)+" <= 0;    \n      ")
            wrFile.write(outStartPortName+" <= 1'b0;              \n      ")
            wrFile.write("end\n    ")
            wrFile.write("else begin                        \n      ")
            for i in range(0, dp):
                wrFile.write(outDataNamePre+str(i)+" <= "+wireOutName+"["+str(i)+"];    \n      ")
            wrFile.write(outStartPortName+" <= out_start_wire;    \n      ")
            wrFile.write("end\n  ")
            wrFile.write("end                              \n")
        else:
            for i in range(0, dp):
                wrFile.write("assign "+outDataNamePre+""+str(i)+" = "+wireOutName+"["+str(i)+"];    \n  ")
            wrFile.write("assign "+outStartPortName+" = out_start_wire;    \n  ")

        wrFile.write("\n")
        wrFile.write("endmodule                        \n\n")

    return moduleName


################################
##genMuxReg("mux_reg")

##genWireCon(fileName, stageIdx, dp, lOrR, dataWidth, regOut)
##genWireCon("genWire.v", 2, 16, "l", 16, True)
##gen2to2Switch("gen2to2Switch.v", 16, True)
##genSwitchesStage("stageSwitches.v", 2, 16, "l", 16, True)

###################Test2
#ctrlIn = []
#for i in range(0, 8):
#    vec = [0,i%2,0,1]
#    ctrlIn.append(vec)
#
#genSwitchCtrl("switchCtrl.v", 1, 8, "l", ctrlIn ) 


#######Test3
dp = 4
regOutSwitch = []
regOutWireCon = []
for i in range(0, int(math.log(dp,2))):
    a, b = 1, 0
    regOutSwitch.append(a)
    regOutWireCon.append(b)

#genStagesBlock("rightBlock.v", dp, "R", 8, regOutSwitch, regOutWireCon, True)


######Test4
addrVec = []
addrVec.append([0,2,1,3])
addrVec.append([0,2,1,3,0,3,2,1])
addrVec.append([0,2,1,3,0,3,2,1,0,1,3,2])
addrVec.append([0,2,1,3])
portStyle = ["dp","sp","sp","dp"]
regOut = False
genMemStage("memStage.v", 4, 16, 8, addrVec, portStyle, regOut)