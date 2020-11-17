#include <stdio.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>

const int arrSize = 10000;
int startArray[arrSize]; // стартовый массив

int raw[arrSize]; // массив некривых заготовок
int rawSize = 0;

int workpiece[arrSize]; // массив заточенных булавок
int workpieceSize = 0;

int product[arrSize]; // массив готовых булавок
int productSize = 0;

int curveSleep = 1000;
int sharpenSleep = 3000;
int controlSleep = 2000;

int startSize;

FILE* fin;
FILE* fout;

pthread_rwlock_t firstLock; // блокировка
pthread_rwlock_t secondLock; // блокировка


//стартовая функция потоков-читателей
void *funcCheckCurve(void *param) {
    int i = 0;
    while(i < startSize)
    {
        pthread_rwlock_wrlock(&firstLock) ;
        if(startArray[i] % 17 != 0){
            raw[rawSize++] = startArray[i];
            fprintf(fout, "pin %d %s\n", startArray[i],"Correct curve");

        }else
            fprintf(fout, "pin %d %s\n", startArray[i],"Incorrect curve");
        pthread_rwlock_unlock(&firstLock) ;
        
        i++;
        usleep(curveSleep);
    }
    return nullptr;
}

//стартовая функция потоков-писателей
void* funcSharpen(void *param) {

    int current;
    int i = 0;
    fprintf(fout, "rawSize %d \n",rawSize );
    while(i < rawSize){
        pthread_rwlock_rdlock(&firstLock) ;

        current = raw[i];

        pthread_rwlock_unlock(&firstLock) ;

        pthread_rwlock_wrlock(&secondLock) ;

        if(random()% 10 != 0){
            workpiece[workpieceSize++] = current * 17;
        }
        else{
            workpiece[workpieceSize++] = current * 11;
        }

        fprintf(fout, "pin %d %s\n", current ,"Sharpen complete");
        // временной довесок
        usleep(sharpenSleep);

        i++;
        pthread_rwlock_unlock(&secondLock) ;

    }

    return nullptr;
}

void * funcControl(void* param){
    int i = 0;
    while(i < workpieceSize){
        pthread_rwlock_rdlock(&secondLock) ;
        // проверка корректности заточки 
        if(workpiece[i]%17 == 0 && workpiece[i]%(17*17) != 0){
            product[productSize++] = workpiece[i];
            fprintf(fout, "%d %s\n", workpiece[i],"OK");
        }    
        else{
            fprintf(fout, "%d %s\n", workpiece[i],"Incorrect sharpen");
        }
        // верменной довесок
        usleep(controlSleep);
        i++;
        pthread_rwlock_unlock(&secondLock) ;
    }


    return nullptr;
}



int main(int argc, char * argv[]) {

    if(argc == 3 ) {
        fin = fopen(argv[1],"r");
        fout = fopen(argv[2],"w");



        fscanf(fin,"%d",&startSize);

        //заполнение начального массива булавок
        for (int i = 0 ; i < startSize ; i++) {
            fscanf(fin,"%d",&startArray[i]) ;
        }
    }
    else if (argc == 2) {
        srand(time(NULL));

        for (int i = 0 ; i < arrSize ; i++) {
            startArray[i] = rand()/(RAND_MAX/100) ;
        }
        startSize = arrSize;
        fout = fopen(argv[1],"w");
    }

    //инициализация блокировки чтения-записи
    pthread_rwlock_init(&firstLock, NULL) ;
    pthread_rwlock_init(&secondLock, NULL) ;


    // создание потоков рабочких
    pthread_t curveControl;
    pthread_t sharpenAction;
    pthread_t controlAction;


    // запускаем измерителя кривизны
    pthread_create(&curveControl, NULL, funcCheckCurve, (void*)NULL) ;

    // запускаем точильщика
    pthread_create(&sharpenAction, NULL, funcSharpen, (void*)NULL) ;
    // задержка для контролера 
    usleep(sharpenSleep + 1000) ;
    // запускаем контролера
    funcControl((void*)NULL) ;

    fprintf(fout, "\n Количество нормальных заготовок: %d\n", rawSize) ;

    fprintf(fout, "\n Количество заточеных булавок: %d\n", workpieceSize) ;

    fprintf(fout, "\n Количество хороших булавок: %d\n", productSize) ;

    pthread_join(sharpenAction,NULL);

    return 0;
}
