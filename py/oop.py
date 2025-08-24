
#!/usr/bin/python3
class SieuNhan():
    def __init__(self, para1, para2):
        self.ten = para1
        self.sucManh = para2
        self.tocDo = 50
        self.khaNang = "Bay"
    def xin_chao(self):
        return "Xin chao toi la " + self.ten

SieuNhanA = SieuNhan("Sieu Nhan", 100)
print(SieuNhanA.xin_chao())