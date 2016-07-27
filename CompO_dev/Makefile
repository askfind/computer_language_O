PROGNAME = O
#LIBS = -ljpeg -ldirectfb -pthread 

INCLUDES = -I/home/vladmir/work_test/C/
LDFLAGS = -Llibs/
OBJECTS = o.o 

CFLAGS = -W -Wall -O2 -ggdb 

all: $(PROGNAME)

$(PROGNAME): $(OBJECTS)
	gcc -o $(PROGNAME) $(OBJECTS) 
    #$(LIBS) $(INCLUDES) $(LDFLAGS)

$(OBJECTS): Makefile

.c.o: 
	gcc -c $(CFLAGS) $(INCLUDES) -o $@ $< 

clean:
	rm *.o $(PROGNAME)
