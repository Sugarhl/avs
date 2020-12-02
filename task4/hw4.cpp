#include <cstdio>
#include <cstdlib>
#include <unistd.h>
#include <omp.h>
#include <iostream>

const int arrSize = 1500;
int pin_cnt = 0;
int raw[arrSize]; // массив некривых заготовок
int rawSize = 0;

int workpiece[arrSize]; // массив заточенных булавок
int workpieceSize = 0;

int product[arrSize]; // массив готовых булавок
int productSize = 0;

int normraw = 0;
int normwork = 0;
int normprod = 0;

int curveSleep = 10;
int sharpenSleep = 30;
int controlSleep = 20;
int end = 0;

FILE *fout;

omp_lock_t firstLock; // блокировка
omp_lock_t secondLock; // блокировка


//стартовая функция рабочего проверяющего кривизну
void funcCheckCurve() {
    int i = 0;
    while (i <= pin_cnt) {
        int pin = rand() % 1000;
        if(i==pin_cnt)
            pin = -1;
        omp_set_lock(&firstLock);
        if (pin % 17 != 0) {
            raw[rawSize++] = pin;
            normraw++;
#pragma omp critical( fout )
            {
                fprintf(fout, "%d pin %d %s\n", i, pin, "Correct curve");
            }
        } else {
#pragma omp critical( fout )
            {
                fprintf(fout, "%d pin %d %s\n", i, pin, "Incorrect curve");
            }
        }
        omp_unset_lock(&firstLock);
        i++;
        usleep(curveSleep);
    }
}
// номер  обработанной булавки
int wokrcnt = 0;
//стартовая функция рабочего точильщика
void funcSharpen() {

    int current;
    while (true) {
        if (rawSize > 0) {
            omp_set_lock(&firstLock);

            current = raw[--rawSize];

            omp_unset_lock(&firstLock);

            omp_set_lock(&secondLock);

            if (random() % 10 != 0) {
                workpiece[workpieceSize++] = current * 17;
                normwork++;
            } else {
                workpiece[workpieceSize++] = current * 11;
            }
#pragma omp critical( fout )
            {
                fprintf(fout, "%d raw %d %s\n",wokrcnt++, current, "Sharpen complete");
            }
            // временной довесок
            omp_unset_lock(&secondLock);

        }
        if(current == -1)
            return;
    }
}
int control = 0;
// стартовая функция контролера
void funcControl() {
    while (true) {
        if (workpieceSize > 0) {
            omp_set_lock(&secondLock);
            // проверка корректности заточки
            if (workpiece[--workpieceSize] % 17 == 0 && workpiece[workpieceSize] % (17 * 17) != 0) {
                product[productSize++] = workpiece[workpieceSize];
                normprod++;
            if(workpiece[workpieceSize] < 0)
                return;
#pragma omp critical( fout )
                {
                    fprintf(fout, "%d workpiece:%d %s \n", control++, workpiece[workpieceSize], "OK");
                }
            } else {
#pragma omp critical( fout )
                {
                    fprintf(fout, "%d workpiece:%d %s\n", control++, workpiece[workpieceSize], "Incorrect sharpen");
                }
            }
            // верменной довесок
            omp_unset_lock(&secondLock);
            usleep(controlSleep);
        }
    }
}


int main(int argc, char *argv[]) {

    if (argc == 3) {
        srand(time(NULL));
        pin_cnt = std::atoi(argv[1]);
        fout = fopen(argv[2], "w");
    } else {
        std::cout << "Ошибка в перечислении параметров";
    }

    //инициализация блокировки чтения-записи
    omp_init_lock(&firstLock);
    omp_init_lock(&secondLock);

#pragma omp parallel sections num_threads(3)
    {
#pragma omp section
        {
#pragma omp parallel num_threads(1) shared (raw, rawSize)
            funcCheckCurve();
        }
#pragma omp section
        {
#pragma omp parallel num_threads(1) shared (raw, rawSize, workpiece, workpieceSize)
            funcSharpen();
        }
#pragma omp section
        {
#pragma omp parallel num_threads(1) shared (workpiece, workpieceSize)
            funcControl();
        }
    }

    omp_destroy_lock(&firstLock);

    omp_destroy_lock(&secondLock);

    fprintf(fout, "\n Количество нормальных заготовок: %d\n",normraw) ;

    fprintf(fout, "\n Количество заточеных булавок: %d\n",normwork);

    fprintf(fout, "\n Количество хороших булавок: %d\n",normprod);
}
