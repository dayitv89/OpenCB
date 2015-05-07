#include <string>
#include <sstream>
#include <iomanip>
#include <stdexcept>

#import "thread.h"
#import "san.h"
#include "direction.h"
#include "evaluate.h"

#include "position.h"

// Whether the main engine thread is ready
bool __mainThreadReady__ = false;

namespace UCI
{
    extern void loop(int argc, char* argv[]);
}

namespace
{
    std::string CurrentMove;
    int CurrentMoveNumber, TotalMoveCount;
}

//extern EngineController *__globalEngineController__;

static int value_to_centipawns(Chess::Value v)
{
    return (int(v) * 100) / int(Chess::Value(0x0C6));
}

static const char PieceChars[] = " pnbrqk";

char piece_type_to_char(PieceType pt, bool upcase = false) {
    return upcase? toupper(PieceChars[pt]) : PieceChars[pt];
}

static const std::string move_to_san(Position& pos, Move m) {
    
    assert(pos.pos_is_ok());
    assert(is_ok(m));
    
    Square from, to;
    PieceType pt;
    
    from = from_sq(m);
    to = to_sq(m);
    pt = type_of(pos.piece_on(from_sq(m)));
    
    std::string san = "";
    
    if (m == MOVE_NONE)
        return "(none)";
    else if (m == MOVE_NULL)
        return "(null)";
    else if (type_of(m) == CASTLE)
    {
        san = to == SQ_A1 ? "O-O-O" : "O-O";
    }
    else
    {
        if (pt != PAWN)
        {
            san += piece_type_to_char(pt, true);
            
            /*
            switch (move_ambiguity(pos, m)) {
                case AMBIGUITY_NONE:
                    break;
                case AMBIGUITY_FILE:
                    san += file_to_char(square_file(from));
                    break;
                case AMBIGUITY_RANK:
                    san += rank_to_char(square_rank(from));
                    break;
                case AMBIGUITY_BOTH:
                    san += square_to_string(from);
                    break;
                default:
                    assert(false);
            }
             */
        }
        if (pos.capture(m))
        {
            if (pt == PAWN)
                san += Chess::file_to_char(static_cast<Chess::File>(file_of(from_sq(m))));
            san += "x";
        }
        san += Chess::square_to_string(static_cast<Chess::Square>(to_sq(m)));
        if (type_of(m) == PROMOTION)
        {
            san += '=';
            san += piece_type_to_char(promotion_type(m), true);
        }
    }
    // Is the move check?  We don't use pos.move_is_check(m) here, because
    // Position::move_is_check doesn't detect all checks (not castling moves,
    // promotions and en passant captures).
    StateInfo st;
    Position p(pos, 0);
    p.do_move(m, st);
    
/*
    if (p.is_check())
        san += p.is_mate()? "#" : "+";
*/

    return san;
}

MainThread * getMainThread()
{
    extern ThreadPool Threads;
    assert(dynamic_cast<MainThread *>(Threads.front()));
    return dynamic_cast<MainThread *>(Threads.front());
}

const std::string line_to_san(const std::string &fen, int line[], int startColumn, bool breakLines, int moveNumbers)
{
    extern int __getMoveIndex__();
    const int __moveIndex__ = __getMoveIndex__();
    unsigned index = __moveIndex__ + 1;

    Position p; p.st = NULL; p.set(fen, false, getMainThread());
    //Position p; p.st = NULL; p.set(fen, false, Threads.main_thread());
    Search::RootColor = p.side_to_move();
    
    bool isWhite = p.side_to_move() == WHITE;
    
    std::stringstream s, ns;
    std::string moveStr;
    int length, maxLength;
    
    length = 0;
    maxLength = 80 - startColumn;
    
    for (int i = 0; line[i] != MOVE_NONE; i++)
    {
        ns.str("");

        if (moveNumbers && p.side_to_move() == WHITE)
        {
            ns << moveNumbers + i/2 << ". ";
        }
        else if(moveNumbers && i == 0)
        {
            ns << moveNumbers + (i+1)/2 << "... ";
        }
        
        moveStr = move_to_san(p, (Move) line[i]);
        length += moveStr.length() + 1;

        if (breakLines && length > maxLength)
        {
            s << "\n";
            
            for(int j = 0; j < startColumn; j++)
            {
                s << " ";
            }

            length = static_cast<unsigned>(moveStr.length()) + 1;
        }

        if (isWhite)
        {
            s << index++ << "." << ns.str() << moveStr << " ";
        }
        else if (!isWhite && i == 0)
        {
            s << index++ << "..." << ns.str() << moveStr << " ";
        }
        else
        {
            s << ns.str() << moveStr << " ";
        }
        
        StateInfo sts;
        
        if (line[i] == MOVE_NULL)
        {
            p.do_null_move(sts);
        }
        else
        {
            p.do_move((Move) line[i], sts);
        }
        
        isWhite = !isWhite;
    }
    
    return s.str();
}

void currmove_to_ui(const std::string currmove, int currmovenum, int movenum)
{
    CurrentMove = currmove;
    CurrentMoveNumber = currmovenum;
    TotalMoveCount = movenum;
}

static const std::string time_string_(int milliseconds)
{    
    std::stringstream s;
    s << std::setfill('0');
    
    int hours = milliseconds / (1000*60*60);
    int minutes = (milliseconds - hours*1000*60*60) / (1000*60);
    int seconds = (milliseconds - hours*1000*60*60 - minutes*1000*60) / 1000;
    
    if (hours)
        s << hours << ':';
    
    s << std::setw(2) << minutes << ':' << std::setw(2) << seconds;
    return s.str();
}

namespace Search {
    
    extern volatile SignalsType Signals;
}

#ifdef SMALLFISH_FRAMEWORK

#pragma mark SmallFish

void __forceEngineStop__()
{
    Search::Signals.stop = true;
}

bool __isPlaying__()
{
    return (__mainThreadReady__ && Threads.timer && getMainThread() ? !Search::Limits.infinite && getMainThread()->thinking : false);
}

bool __isAnalyzing__()
{
    return (__mainThreadReady__ && Threads.timer && getMainThread() ? Search::Limits.infinite && getMainThread()->thinking : false);
}

void __waitUntilThinkCompleted__()
{
    NSUInteger retries = 0;

    while (__isPlaying__())
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
        retries++;
        
        if (retries >= 6)
        {
            NSLog(@"---------------- Warning ---------------- --> Break out __waitUntilThinkCompleted__");
            break;
        }
    }
}

void __waitUntilAnalyzeCompleted__()
{
    __waitUntilThinkCompleted__();
}

#pragma end

#endif

#pragma mark Engine To UI

extern void engineSendAnalysis(int i, const Position& pos, std::vector<Search::RootMove> &roots, std::size_t size, long depth, Value value)
{
    const bool isUserWhite = (pos.side_to_move() == WHITE);
    
    // The value received from the engine is always evaluated from the perspective of the engine, we need to revert it back
    const float score = Chess::value_to_centipawns(isUserWhite ? (Chess::Value) value : (Chess::Value) -value) / 100.0;

    /*
     * Show evaluation scores. Note that the value is calculated from the engine's perspective.
     */
    
    //[__globalEngineController__ showScore:[NSNumber numberWithFloat:score]];
    
    /*
     * Show analysis
     */
    
    std::stringstream ss;
    
    if (abs(value) >= VALUE_MATE_IN_MAX_PLY)
    {
        const int mate = (value > 0 ? VALUE_MATE - value + 1 : -VALUE_MATE - value) / 2;

        if (value < 0)
        {
            ss << '#' << abs(mate);
        }
        else
        {
            ss << '#' << abs(mate);
        }
    }
    else
    {
        ss << (((isUserWhite && value > 0) || (!isUserWhite && value < 0))? "+" : "") << std::setiosflags(std::ios::fixed) << std::setprecision(1) << score;
    }

    // Defined in san.cpp
    extern std::string createAnalysis(const std::string &fen,
                                      const std::vector<int> &types,
                                      const std::vector<std::pair<unsigned, unsigned> > &srcs,
                                      const std::vector<std::pair<unsigned, unsigned> > &dsts,
                                      const std::vector<int> &promotes,
                                      bool appendMoveNumber);
    
    static NSInteger __depth__;
    static std::vector<std::vector<int> > __types__;
    static std::vector<std::vector<int> > __promotes__;
    static std::vector<std::vector<std::pair<unsigned, unsigned> > > __srcs__;
    static std::vector<std::vector<std::pair<unsigned, unsigned> > > __dsts__;

    __depth__ = depth;
    
    __srcs__.reserve(size);
    __dsts__.reserve(size);
    __types__.reserve(size);
    __promotes__.reserve(size);

    __srcs__.clear();
    __dsts__.clear();
    __types__.clear();
    __promotes__.clear();

    for (unsigned i = 0; i < size; i++)
    {
        if (i && !Search::Limits.infinite && fabs(roots[i].score - roots[0].score) >=  2.0)
        {
            break;
        }
        
        const std::vector<Move> &pv = roots[i].pv;
        
        __types__.push_back(std::vector<int>());
        __promotes__.push_back(std::vector<int>());
        __srcs__.push_back(std::vector<std::pair<unsigned, unsigned> >());
        __dsts__.push_back(std::vector<std::pair<unsigned, unsigned> >());

        for (std::size_t j = 0; pv[j] != MOVE_NONE; j++)
        {
            const Move &move = pv[j];
            const Square src = from_sq(move);
            Square dst = to_sq(move);
            
            switch (type_of(move))
            {
                case PROMOTION: { __types__[i].push_back(3); break; }
                case ENPASSANT: { __types__[i].push_back(2); break; }
                case CASTLE:    { __types__[i].push_back(1); break; }
                default:        { __types__[i].push_back(0); break; }
            }
            
            if (type_of(move) == PROMOTION)
            {
                __promotes__[i].push_back(promotion_type(move));
            }
            else
            {
                __promotes__[i].push_back(QUEEN);
            }
            
            __srcs__[i].push_back(std::pair<int,int>(file_of(src), rank_of(src)));
            __dsts__[i].push_back(std::pair<int,int>(file_of(dst), rank_of(dst)));
        }
    }

//    for (std::size_t i = 0; i < __srcs__.size(); i++)
    {
        const std::string line = createAnalysis(pos.fen(),
                                    __types__[i],
                                    __srcs__[i],
                                    __dsts__[i],
                                    __promotes__[i],
                                    false);

        extern void __analysisHasReceived__(int i, float score, int depth, const std::string &line);
        __analysisHasReceived__(i, score, depth, line);
    }
}

#pragma end