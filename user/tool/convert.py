octal_number = input("instruction:\t")  # 16进制数

# 将8进制数转换为二进制字符串
instruction = bin(int(octal_number, 16))[2:].zfill(32)  # [2:] 是为了去除前缀 '0b'

print("binary code:\t",instruction)  # 输出二进制字符串

opcode=instruction[25:]
print("opcode:\t",opcode)

func_code = instruction[1]+instruction[17:20]
print("func_code:\t",func_code[0]," ",func_code[1:4])

special_func_code = func_code == "0001" or func_code == "0101" or func_code == "1101";
R_type          = (opcode == "0110011") or (opcode == "0010011" and special_func_code);
I_type          = (opcode == "0010011" and (not special_func_code))or(opcode == "0000011")or(opcode == "1100111"and func_code[1:4] == "000");
S_type          = opcode == "0100011";
B_type          = opcode == "1100011";
U_type          = opcode == "0110111" or opcode == "0010111";
J_type          = opcode == "1101111" and (func_code[1:4] == "000");

rs1=""
rs2=""
rd=""
imm=""

if R_type:
    print("Rtype")
    rs1=instruction[12:17]
    rs2=instruction[7:12]
    rd=instruction[20:25]

elif I_type:
    print("I type")
    rs1=instruction[12:17]
    rd=instruction[20:25]
    imm=instruction[0:12]

elif S_type:
    print("S type")
    rs1=instruction[12:17]
    rs2=instruction[7:12]
    imm=instruction[0:7]+instruction[20:25]

elif B_type:
    print("B type")
    rs1=instruction[12:17]
    rs2=instruction[7:12]
    imm=instruction[0]+instruction[24]+instruction[1:7]+instruction[20:24]+"0"

elif U_type:
    print("U type")
    imm=instruction[0:20]
    rd=instruction[20:25]+"000000000000"

elif J_type:
    print("J type")
    imm=instruction[0]+instruction[12:20]+instruction[11]+instruction[1:11]+"0"
    rd=instruction[20:25]

print("rs1:\t",rs1)
print("rs2:\t",rs2)
print("rs2:\t",rs2)
immediate=(int(imm,2))
print("imm:\t",imm,'\t',immediate,'\t',hex(immediate))