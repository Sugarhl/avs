#include <cstdlib>
#include <pthread.h>
#include <string>
#include <utility>
#include <vector>
#include <iostream>
#include <fstream>
#include <algorithm>
#include <semaphore.h>
#include <zconf.h>
#include <filesystem>

using namespace std;

int talkerCount;

class Talker;

vector<Talker> talkers;

pthread_mutex_t print;
int const talksCount = 1000000;

int talkPhrasesCnt[talksCount];
int nextTalk = 0;
vector<pthread_mutex_t *> talkLocks;

ofstream logger;
bool console = true;

void log(int number, const string &message) {
    pthread_mutex_lock(&print);
    if (console) { cout << number << message << endl; }
    else { logger << number << message << endl; }

    pthread_mutex_unlock(&print);
}

void log(int number, const string &message, int numbertoCall) {
    pthread_mutex_lock(&print);
    if (console) { cout << number << message << numbertoCall << endl; }
    else { logger << number << message << numbertoCall << endl; }
    pthread_mutex_unlock(&print);
}

void log(int number, const string &message, int numbertoCall, const string &succsess) {
    pthread_mutex_lock(&print);
    if (console) { cout << number << message << numbertoCall << "\n\t" << succsess << endl; }
    else { logger << number << message << numbertoCall << "\n\t" << succsess << endl; }
    pthread_mutex_unlock(&print);
}


enum class Statement {
    wait,
    call,
    talk,
    listen,
    refresh
};

struct Talker {
public:
    Statement state;
    int number;
    string name;
    string message;
    bool wasCall;
    bool isWaiter;
    int talkInd = -1;
    int numberToCall = -1;
    pthread_mutex_t lock{};
    sem_t sem{};
    pthread_mutex_t *talkLock;


    Talker(int number, string name, string message, int state) {
        this->number = number;
        this->name = move(name);
        this->message = move(message);
        this->state = static_cast<Statement>(state);
        this->wasCall = state;
        this->isWaiter = state == 0;
        sem_init(&sem, 0, 0);
        pthread_mutex_init(&lock, nullptr);
        talkLock = nullptr;
    }
};

// Функция жизни болтуна
[[noreturn]] void *live(void *param) {
    auto *me = (Talker *) param;

    while (true) {
        // Саспределение по состояниям
        switch (me->state) {
            // Состояние ожидания вызова
            case Statement::wait: {
                log(me->number, " wait for the call");
                sem_wait(&me->sem);
                pthread_mutex_lock(&me->lock);
                me->state = Statement::listen;
                pthread_mutex_unlock(&me->lock);
                break;
            }
                /* Состояние звонка
                 * болтун выбирает номер и звонит
                 * если успешно дозвонилася сообщает другому данные разговора и переходит в состояние говорения
                 * иначе не меняя состояние выходит
                 */
            case Statement::call: {

                pthread_mutex_lock(&me->lock);
                me->numberToCall = ((me->number + 1 + rand() % (talkerCount - 1)) % talkerCount);
                pthread_mutex_unlock(&me->lock);

                pthread_mutex_lock(&(talkers[me->numberToCall].lock));
                Talker *buddy = &talkers[me->numberToCall];

                if (buddy->isWaiter) {
                    log(me->number, " call ", me->numberToCall, "The call was successful");

                    buddy->numberToCall = me->number;
                    buddy->talkInd = nextTalk;
                    buddy->talkLock = talkLocks.back();
                    buddy->isWaiter = false;
                    sem_post(&buddy->sem);

                    pthread_mutex_unlock(&(talkers[me->numberToCall].lock));

                    pthread_mutex_lock(&me->lock);
                        me->state = Statement::talk;
                        me->talkInd = nextTalk++;
                        me->talkLock = talkLocks.back();
                        string path = "talks/talk" + to_string(min(me->number, me->numberToCall)) + "_" +
                                      to_string(max(me->number, me->numberToCall)) + ".txt";
                    pthread_mutex_unlock(&me->lock);

                    pthread_mutex_lock(&print);
                        ofstream fout(path, std::ios_base::app);

                        fout << "---------------Talk started----------------\n";
                        fout.close();
                    pthread_mutex_unlock(&print);

                    talkLocks.pop_back();
                } else {
                    pthread_mutex_unlock(&(talkers[me->numberToCall].lock));
                    log(me->number, " call ", me->numberToCall, "The call failed");
                    usleep(20000);
                }
                break;
            }
                /* Состояние слушателя
                 * в нем мы ждем пока собеседник договорит если это балы последняя фраза идем в состояние обновления
                 * иначе идем в сотояние говорения
                 */
            case Statement::listen: {

                log(me->number, " listen ", me->numberToCall);
                sem_wait(&me->sem);

                pthread_mutex_lock(&me->lock);
                    if (talkPhrasesCnt[me->talkInd]) {
                        me->state = Statement::talk;
                    } else {
                        me->state = Statement::refresh;
                    }
                pthread_mutex_unlock(&me->lock);

                break;
            }
                /* Состояние говорения
                 * болтун дописывает в файл разговора свои слова
                 * после выходит в состояние слушателя если диалог не окончен
                 * иначе идет в состояние обновления
                 * */
            case Statement::talk: {
                pthread_mutex_lock(&me->lock);
                    log(me->number, " talk to ", me->numberToCall);
                    string path = "talks/talk" + to_string(min(me->number, me->numberToCall)) + "_" +
                                  to_string(max(me->number, me->numberToCall)) + ".txt";
                pthread_mutex_unlock(&me->lock);

                pthread_mutex_lock(&print);
                    ofstream fout(path, std::ios_base::app);
                    fout << me->name << ":\n\t" <<
                         "Hi, " << talkers[me->numberToCall].name << "!\n\t";

                    for (int i = 'a'; i < 'z'; i++) {
                        fout << char('a' + rand() % ('z' - 'a'));
                    }

                    fout << "\n\t" + me->message + "\n";
                pthread_mutex_lock(&me->lock);
                if (--talkPhrasesCnt[me->talkInd]) {
                    me->state = Statement::listen;
                } else {
                    pthread_mutex_lock(me->talkLock);
                        fout << "--------------End of the talk--------------\n\n";
                    pthread_mutex_unlock(me->talkLock);
                    me->state = Statement::refresh;
                }
                    fout.close();
                pthread_mutex_unlock(&print);
                pthread_mutex_unlock(&me->lock);

                sem_post(&talkers[me->numberToCall].sem);

                break;
            }
                /* Состояние обновления
                 * сброс всех параметров разговора и переход в одно из состояний
                 * ожидание или звонок
                */
            case Statement::refresh: {

                pthread_mutex_lock(&me->lock);
                if (me->number < me->numberToCall) {
                    talkLocks.push_back(me->talkLock);
                }
                me->talkLock = nullptr;
                if (me->wasCall) {
                    me->state = Statement::wait;
                    me->isWaiter = true;
                } else {
                    me->state = Statement::call;
                }

                me->wasCall = !me->wasCall;

                pthread_mutex_unlock(&me->lock);
                break;
            }
        }
    }
}

int main(int argc, char **argv) {
    ifstream inp;
    ofstream out;

    system("mkdir -p talks");
    int time = 0; // время работы
    int phrases = 2; // количество фраз

    if (argc == 5) {
        talkerCount = stoi(argv[1]);
        inp = ifstream(argv[2]);
        phrases = stoi(argv[3]);
        time = stoi(argv[4]);
    }

    else if (argc == 6) {
        talkerCount = stoi(argv[1]);
        inp = ifstream(argv[2]);
        logger = ofstream(argv[3]);
        console = false;
        phrases = stoi(argv[4]);
        time = stoi(argv[5]);
    }
    else{
        cout << "Нервеный формат агументов командной строки." << endl;
    }

    pthread_t threads[talkerCount];

    // создание болтунов
    for (int i = 0; i < talkerCount; ++i) {
        string name;
        string message;
        int state;
        inp >> name;
        inp >> message;
        inp >> state;
        if (state < 0 || state > 1) {
            cerr << "Неверное состояние болтуна";
            return 1;
        }
        Talker talker(i, name, message, state);
        talkers.push_back(talker);
    }

    // мьютексы разговоров
    for (int i = 0; i < (talkerCount + 1); ++i) {
        pthread_mutex_t lock;
        pthread_mutex_init(&lock, nullptr);
        talkLocks.push_back(&lock);
    }
    // устанавливаем количество фраз
    for (int &i : talkPhrasesCnt) {
        i = phrases;
    }
    // запускаем болтунов
    for (int i = 0; i < talkerCount; ++i) {
        pthread_create(&threads[i], nullptr, live, (void *) &talkers[i]);
        usleep(100);
    }

    sleep(time);
    return 0;
}
