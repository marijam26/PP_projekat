//OPIS: dve globalne promenljive
//RETURN: 25

struct Book{
	int c;
	int b;
};


struct Book boo;

int main() {
    int a;
    boo.c=25;
    a = boo.c + 5;
    return boo.c;

}


