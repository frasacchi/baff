classdef Ply
    properties
        Z0 double;
        NSM double;
        SB double;
        FT string {mustBeMember(FT,["HILL","HOFF","TSAI","STRN","HFAIL","HTAPE","HFABR",""])} = "";
        TREF double = 0;
        GE double = 0;
        LAM string {mustBeMember(LAM,["SYM","MEM","BEND","SMEAR","SMCORE",""])} = "";

        MIDi(:,1) double = [];
        Ti(:,1) double = [];
        THETAi(:,1) double = [];
        SOUTi(:,1) string = [];
    end

    methods
        function obj = Ply(Z0,NSM,SB,FT,TREF,GE,LAM,MIDi,Ti,THETAi,SOUTi)
            arguments
                Z0 double;
                NSM double;
                SB double;
                FT string {mustBeMember(FT,["HILL","HOFF","TSAI","STRN","HFAIL","HTAPE","HFABR",""])} = "";
                TREF double = 0;
                GE double = 0;
                LAM string {mustBeMember(LAM,["SYM","MEM","BEND","SMEAR","SMCORE",""])} = "";

                MIDi(:,1) double = [];
                Ti(:,1) double = [];
                THETAi(:,1) double = [];
                SOUTi(:,1) string = [];
            end

               obj.Z0 = Z0;
               obj.NSM = NSM;
               obj.SB = SB;
               obj.FT = FT;
               obj.TREF = TREF;
               obj.GE = GE;
               obj.LAM = LAM;
               obj.MIDi = MIDi;
               obj.Ti = Ti;
               obj.THETAi = THETAi;
               obj.SOUTi = SOUTi;
        end

    end
end

