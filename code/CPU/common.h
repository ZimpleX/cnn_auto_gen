//
// Created by chizhang on 7/6/16.
//

#ifndef APP_COMMON_H
#define APP_COMMON_H

#include <aalsdk/AAL.h>
#include <aalsdk/xlRuntime.h>
#include <aalsdk/AALLoggerExtern.h> // Logger

#include <aalsdk/service/ISPLAFU.h>       // Service Interface
#include <aalsdk/service/ISPLClient.h>    // Service Client Interface
#include <aalsdk/kernel/vafu2defs.h>      // AFU structure definitions (brings in spl2defs.h)

#include <string.h>
#include <ctime>
#include <time.h>
#include <sys/time.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include <iostream>
#include <fstream>
#include <stdexcept>

// Convenience macros for printing messages and errors.
#ifdef MSG
# undef MSG
#endif // MSG
#define MSG(x) std::cout << __AAL_SHORT_FILE__ << ':' << __LINE__ << ':' << __AAL_FUNC__ << "() : " << x << std::endl
#ifdef ERR
# undef ERR
#endif // ERR
#define ERR(x) std::cerr << __AAL_SHORT_FILE__ << ':' << __LINE__ << ':' << __AAL_FUNC__ << "() **Error : " << x << std::endl

// Print/don't print the event ID's entered in the event handlers.
#if 1
# define EVENT_CASE(x) case x : MSG(#x);
#else
# define EVENT_CASE(x) case x :
#endif

#ifndef CL
# define CL(x)                     ((x) * 64)  // 64 bytes = 512 bits
#endif // CL
#ifndef LOG2_CL
# define LOG2_CL                   6
#endif // LOG2_CL
#ifndef MB
# define MB(x)                   ((x) * 1024 * 1024)
#endif // MB
#define LPBK1_BUFFER_SIZE        CL(1)

#define LPBK1_DSM_SIZE           MB(4);
/// @addtogroup convLayer

struct OneCL {                      // Make a cache-line sized structure
    AAL::btUnsigned32bitInt dw[16];       //    for array arithmetic
};

struct OneCLSingle {
    float dw[16];     // 32 bits single precision
};

struct OneCLDouble {
    double dw[8];     // 16 bits double precision
};


void dumpOneCachelineFile(std::ofstream &dumpFile, struct OneCL *cacheline) {
    for (int i = 0; i < 16; i++) {
        dumpFile << std::hex << std::setfill('0') << std::setw(8) << cacheline->dw[i] << " ";
    }
    dumpFile << std::endl;
}

// time related
double calculate_time_interval(timespec late, timespec early, string precision) {
    timespec time_difference;
    if (late.tv_nsec < early.tv_nsec) {
        time_difference.tv_sec = late.tv_sec - early.tv_sec - 1;
        time_difference.tv_nsec = late.tv_nsec - early.tv_nsec + 1000000000;
    } else {
        time_difference.tv_sec = late.tv_sec - early.tv_sec;
        time_difference.tv_nsec = late.tv_nsec - early.tv_nsec;
    }
    if (precision == "s") {
        return time_difference.tv_sec + (double) time_difference.tv_nsec / 1e9;
    } else if (precision == "ms") {
        return time_difference.tv_sec * 1000 + (double) time_difference.tv_nsec / 1e6;
    } else if (precision == "us") {
        return time_difference.tv_sec * 1e6 + (double) time_difference.tv_nsec / 1e3;
    } else if (precision == "ns") {
        return time_difference.tv_sec * 1e9 + time_difference.tv_nsec;
    } else {
        throw std::invalid_argument("Invalid argument precision");
    }
}


#endif //APP_COMMON_H
