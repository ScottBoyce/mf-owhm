      MODULE GWFRIVMODULE
        USE BUDGET_GROUP_INTERFACE,          ONLY: BUDGET_GROUP
        USE GENERIC_OUTPUT_FILE_INSTRUCTION, ONLY: GENERIC_OUTPUT_FILE
        PRIVATE:: BUDGET_GROUP, GENERIC_OUTPUT_FILE
        !
        TYPE(BUDGET_GROUP),  SAVE, POINTER:: RIVBUD
        CHARACTER(20),DIMENSION(:),SAVE,POINTER::RIVGROUP
        INTEGER,SAVE,POINTER:: IOUT, LOUT
        INTEGER,SAVE,POINTER  ::NRIVER,MXRIVR,NRIVVL,IRIVCB,IPRRIV
        INTEGER,SAVE,POINTER  ::NPRIV,IRIVPB,NNPRIV
        CHARACTER(LEN=16),SAVE, DIMENSION(:), POINTER,CONTIGUOUS::RIVAUX
        REAL,             SAVE, DIMENSION(:,:), POINTER,CONTIGUOUS::RIVR
        TYPE(GENERIC_OUTPUT_FILE), POINTER,SAVE:: RIVDB
      TYPE GWFRIVTYPE
        TYPE(BUDGET_GROUP), POINTER:: RIVBUD
        CHARACTER(20),DIMENSION(:),POINTER::RIVGROUP
        INTEGER,POINTER:: IOUT, LOUT
        INTEGER,POINTER  ::NRIVER,MXRIVR,NRIVVL,IRIVCB,IPRRIV
        INTEGER,POINTER  ::NPRIV,IRIVPB,NNPRIV
        CHARACTER(LEN=16), DIMENSION(:),   POINTER,CONTIGUOUS::RIVAUX
        REAL,              DIMENSION(:,:), POINTER,CONTIGUOUS::RIVR
        TYPE(GENERIC_OUTPUT_FILE), POINTER:: RIVDB
      END TYPE
      TYPE(GWFRIVTYPE), SAVE:: GWFRIVDAT(10)
      END MODULE GWFRIVMODULE


      SUBROUTINE GWF2RIV7AR(IN,IGRID)
C     ******************************************************************
C     ALLOCATE ARRAY STORAGE FOR RIVERS AND READ PARAMETER DEFINITIONS.
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE CONSTANTS,                        ONLY: BLN
      USE ERROR_INTERFACE,                  ONLY: STOP_ERROR
      USE FILE_IO_INTERFACE,                ONLY: READ_TO_DATA
      USE PARSE_WORD_INTERFACE,             ONLY: PARSE_WORD_UP
      USE GENERIC_BLOCK_READER_INSTRUCTION, ONLY: GENERIC_BLOCK_READER
      USE GLOBAL,       ONLY:LIST_UNIT=>IOUT,NCOL,NROW,NLAY,IFREFM
      USE GWFRIVMODULE, ONLY:NRIVER,MXRIVR,NRIVVL,IRIVCB,IPRRIV,NPRIV,
     1                       IRIVPB,NNPRIV,RIVAUX,RIVR,RIVDB,
     2                       RIVBUD,IOUT,LOUT,RIVGROUP
C
      TYPE(GENERIC_BLOCK_READER):: BL
      CHARACTER(768):: LINE
      LOGICAL:: FOUND_BEGIN
C     ------------------------------------------------------------------
C
C1------Allocate scalar variables, which makes it possible for multiple
C1------grids to be defined.
      ALLOCATE(NRIVER,MXRIVR,NRIVVL,IRIVCB,IPRRIV,NPRIV,IRIVPB,NNPRIV)
      ALLOCATE(IOUT,LOUT)
      ALLOCATE(RIVDB)
      LOUT=LIST_UNIT
      IOUT=LIST_UNIT
C 
C
C1------SET AUXILIARY VARIABLES AND PRINT OPTION.
      ALLOCATE (RIVAUX(20))
      NAUX=0
      IPRRIV=1
      !
      CALL READ_TO_DATA(LINE,IN,LOUT,LOUT)
      !
      IOUT = LIST_UNIT
C
C2------IDENTIFY PACKAGE AND INITIALIZE NRIVER AND NNPRIV.
        WRITE(IOUT,1)IN
    1 FORMAT(1X,/1X,'RIV -- RIVER PACKAGE, VERSION OWHM',
     1' INPUT READ FROM UNIT ',I4)
      NRIVER=0
      NNPRIV=0
C
C  START LOAD OF DATA
C
C3------READ MAXIMUM NUMBER OF RIVER REACHES AND UNIT OR FLAG FOR
C3------CELL-BY-CELL FLOW TERMS.
      CALL UPARLSTAL(IN,IOUT,LINE,NPRIV,MXPR)
      !
      !Check for BEGIN BUDGET_GROUPS BLOCK and load Budget Names
      ALLOCATE(RIVBUD)
      !
      CALL RIVBUD%INIT('RIVER LEAKAGE')
      !
      DO !BLOCK GROUPS
      !
      CALL BL%LOAD(IN,IOUT,LINE=LINE,FOUND_BEGIN=FOUND_BEGIN)
      !
      IF(BL%NAME == 'PARAMETER') THEN
          CALL UPARLSTAL(IN,IOUT,LINE,NPRIV,MXPR)
          CYCLE
      END IF
      !
      IF (.NOT. FOUND_BEGIN) EXIT
      !
      IF(BL%NAME == 'BUDGET_GROUP' .OR. BL%NAME == 'BUDGET_GROUPS') THEN
        CALL RIVBUD%LOAD(BL)
        !
      ELSEIF(BL%NAME == 'OPTION' .OR. BL%NAME == 'OPTIONS' ) THEN
        !
        WRITE(IOUT,'(/1X,A)') 'PROCESSING RIV OPTIONS'
        !
        CALL BL%START()
        DO I=1, BL%NLINE
        LLOC = 1
        CALL PARSE_WORD_UP(BL%LINE,LLOC,ISTART,ISTOP)
        !
        SELECT CASE (BL%LINE(ISTART:ISTOP))
        CASE('AUXILIARY','AUX')
            CALL PARSE_WORD_UP(BL%LINE,LLOC,ISTART,ISTOP)
            IF(NAUX.LT.20) THEN
               NAUX=NAUX+1
               RIVAUX(NAUX)=LINE(ISTART:ISTOP)
                 WRITE(IOUT,12) RIVAUX(NAUX)
   12          FORMAT(1X,'AUXILIARY RIVER VARIABLE: ',A)
            END IF
        CASE('NOPRINT') 
            WRITE(IOUT,13)
   13       FORMAT(1X,'LISTS OF RIVER CELLS WILL NOT BE PRINTED')
            IPRRIV = 0
        CASE('DBFILE') !ADD KEYWORD TO WRITE ONCE
           !CALL PARSE_WORD_UP(BL%LINE,LLOC,ISTART,ISTOP)
           WRITE(IOUT,715)
  715   FORMAT(1X,'RIV INFORMATION WRITTEN TO DATABASE FRIENDLY OUTPUT')
           CALL RIVDB%OPEN(BL%LINE,LLOC,IOUT,IN,NO_INTERNAL=.TRUE.,
     +                     ALLOW_ONLY_UNIT=.TRUE.)
           IF(RIVDB%BINARY) THEN !IF FILE NOT OPEN THEN NO HEADER IS WRITTEN AND ONLY WRITE HEADER IF NOT BINARY.
               WRITE(IOUT,'(*(A))')'RIV DATABASE FRIENDLY OUTPUT ',
     +         'WRITTEN TO BINARY FILE USING STREAM UNFORMATTED ',
     +         'STRUCTURE.',NL,
     +         'EACH THE RECORD IN BINARY HAS THE FOLLOWING STRUCTURE:',
     +          NL,'"DATE_START (19char), ',
     +         'STRESS PERIOD (int), TIME STEP (int), ',
     +         'TIME STEP LENGTH (double),  SIMULATED TIME (double), ',
     +         'LAY (int), ROW (int), COL (int), ',
     +         'RIV CONDUCTANCE (double), RIV HEAD (double), ',
     +         'RIV BOTTOM (double), GROUNDWATER HEAD (double), ', 
     +         'RIV FLOW RATE (double), RIV BUDGET GROUP (16char)'
           ELSE
              CALL RIVDB%SET_HEADER( ' DATE_START               '//
     +        'PER     STP             DELT          '//
     +        'SIMTIME    LAY    ROW    COL  RIV_CONDUCTANCE       '//
     +        'RIV_HEAD         RIV_BOTTOM            HEAD    '//
     +        'RIV_FLOW_RATE   RIV_BUD_GROUP' )
           END IF
        CASE DEFAULT
            ! -- NO OPTIONS FOUND
            WRITE(IOUT,'(/2A,A/)')
     +             'RIV WARNING: FAILED TO IDENTIFY OPTION: ',
     +              BL%LINE(ISTART:ISTOP),
     +             'THIS OPTION IS IGNORED AND NOT APPLIED.'
        END SELECT
        CALL BL%NEXT()
        END DO
        !
        ELSE
           CALL STOP_ERROR(TRIM(LINE),IN,IOUT,
     +  'RIV BLOCK ERROR. FOUND "BEGIN" KEYWORD, BUT IT WAS '//
     +  ' NOT FOLLOWED BY A KNOWN BLOCK NAME.'//BLN//
     +  'THE FOLLOWING ARE ACCEPTED BLOCK NAMES: '//
     +  '"BUDGET_GROUP", "BUDGET_GROUPS", "OPTION", and "OPTIONS"' )
        END IF
        !
      END DO  !BLOCK GROUPS
      !
      !
      IF(IFREFM.EQ.0) THEN
         READ(LINE,'(2I10)', IOSTAT=N) MXACTR,IRIVCB
         IF(N.NE.0) THEN
               LLOC=1
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,MXACTR,R,LOUT,IN)
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IRIVCB,R,LOUT,IN)
         END IF
         LLOC=21
      ELSE
         LLOC=1
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,MXACTR,R,LOUT,IN)
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IRIVCB,R,LOUT,IN)
      END IF
      !
      ! CHECK IF GLOBAL SHUTDOWN OF CBC IS IN EFFECT
       CALL CHECK_CBC_GLOBAL_UNIT(IRIVCB)
      !
        WRITE(IOUT,3) MXACTR
    3 FORMAT(1X,'MAXIMUM OF ',I6,' ACTIVE RIVER REACHES AT ONE TIME')
        IF(IRIVCB.LT.0) WRITE(IOUT,7)
    7 FORMAT(1X,'CELL-BY-CELL FLOWS WILL BE PRINTED WHEN ICBCFL NOT 0')
        IF(IRIVCB.GT.0) WRITE(IOUT,8) IRIVCB
    8 FORMAT(1X,'CELL-BY-CELL FLOWS WILL BE SAVED ON UNIT ',I4)
C
C4------READ AUXILIARY VARIABLES AND PRINT OPTION.
      !
   10 CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,IN)
      IF(LINE(ISTART:ISTOP).EQ.'AUXILIARY' .OR.
     1        LINE(ISTART:ISTOP).EQ.'AUX') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,IN)
         IF(NAUX.LT.20) THEN
            NAUX=NAUX+1
            RIVAUX(NAUX)=LINE(ISTART:ISTOP)
              WRITE(IOUT,12) RIVAUX(NAUX)
         END IF
         GO TO 10
      ELSE IF(LINE(ISTART:ISTOP).EQ.'NOPRINT') THEN
           WRITE(IOUT,13)
         IPRRIV = 0
         GO TO 10
      END IF
C
C5------ALLOCATE SPACE FOR RIVER ARRAYS.
C5------FOR EACH REACH, THERE ARE SIX INPUT DATA VALUES PLUS ONE
C5------LOCATION FOR CELL-BY-CELL FLOW.
      NRIVVL=7+NAUX
      IRIVPB=MXACTR+1
      MXRIVR=MXACTR+MXPR
      ALLOCATE (RIVR(NRIVVL,MXRIVR))
      !
      IF (RIVBUD%BUDGET_GROUPS) THEN
          ALLOCATE(RIVGROUP(MXRIVR))
      ELSE
          ALLOCATE(RIVGROUP(1))
          RIVGROUP='NOGROUP'
      END IF
C
C6------READ NAMED PARAMETERS.
        WRITE(IOUT,99) NPRIV
   99 FORMAT(1X,//1X,I5,' River parameters')
      IF(NPRIV.GT.0) THEN
        LSTSUM=IRIVPB
        DO 120 K=1,NPRIV
          LSTBEG=LSTSUM
          CALL UPARLSTRP(LSTSUM,MXRIVR,IN,IOUT,IP,'RIV','RIV',1,
     &                   NUMINST)
          NLST=LSTSUM-LSTBEG
          IF (NUMINST.EQ.0) THEN
C6A-----READ PARAMETER WITHOUT INSTANCES
            CALL ULSTRD(NLST,RIVR,LSTBEG,NRIVVL,MXRIVR,1,IN,
     &            IOUT,'REACH NO.  LAYER   ROW   COL'//
     &            '     STAGE    STRESS FACTOR     BOTTOM EL.',
     &            RIVAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRRIV,
     &            RIVGROUP)
          ELSE
C6B-----READ INSTANCES
            NINLST = NLST/NUMINST
            DO 110 I=1,NUMINST
            CALL UINSRP(I,IN,IOUT,IP,IPRRIV)
            CALL ULSTRD(NINLST,RIVR,LSTBEG,NRIVVL,MXRIVR,1,IN,
     &            IOUT,'REACH NO.  LAYER   ROW   COL'//
     &            '     STAGE    STRESS FACTOR     BOTTOM EL.',
     &            RIVAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRRIV,
     &            RIVGROUP)
            LSTBEG=LSTBEG+NINLST
  110       CONTINUE
          END IF
  120   CONTINUE
      END IF
C
C7------SAVE POINTERS TO DATA AND RETURN.
      CALL SGWF2RIV7PSV(IGRID)
      RETURN
      END
      SUBROUTINE GWF2RIV7RP(IN,IGRID)
C     ******************************************************************
C     READ RIVER HEAD, CONDUCTANCE AND BOTTOM ELEVATION
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:NCOL,NROW,NLAY,IFREFM,BOTM,LBOTM,
     1                       IBOUND
      USE GWFRIVMODULE, ONLY:NRIVER,MXRIVR,NRIVVL,IPRRIV,NPRIV,
     1                       IRIVPB,NNPRIV,RIVAUX,RIVR,LOUT,RIVBUD,
     2                       IOUT,LOUT,RIVGROUP
C     ------------------------------------------------------------------
      CALL SGWF2RIV7PNT(IGRID)
C
C1------READ ITMP (NUMBER OF RIVER REACHES OR FLAG TO REUSE DATA) AND
C1------NUMBER OF PARAMETERS.
      IF(NPRIV.GT.0) THEN
         IF(IFREFM.EQ.0) THEN
            READ(IN,'(2I10)') ITMP,NP
         ELSE
            READ(IN,*) ITMP,NP
         END IF
      ELSE
         NP=0
         IF(IFREFM.EQ.0) THEN
            READ(IN,'(I10)') ITMP
         ELSE
            READ(IN,*) ITMP
         END IF
      END IF
C
C------CALCULATE SOME CONSTANTS
      NAUX=NRIVVL-7
      IOUTU = IOUT
      !IF (IPRRIV.EQ.0) IOUTU = -IOUT
C
C2------DETERMINE THE NUMBER OF NON-PARAMETER REACHES.
      IF(ITMP.LT.0) THEN
           WRITE(IOUT,7)
    7    FORMAT(1X,/1X,
     1   'REUSING NON-PARAMETER RIVER REACHES FROM LAST STRESS PERIOD')
      ELSE
         NNPRIV=ITMP
      END IF
C
C3------IF THERE ARE NEW NON-PARAMETER REACHES, READ THEM.
      MXACTR=IRIVPB-1
      IF(ITMP.GT.0) THEN
         IF(NNPRIV.GT.MXACTR) THEN
              WRITE(LOUT,99) NNPRIV,MXACTR
   99       FORMAT(1X,/1X,'THE NUMBER OF ACTIVE REACHES (',I6,
     1                     ') IS GREATER THAN MXACTR(',I6,')')
            CALL USTOP(' ')
         END IF
         CALL ULSTRD(NNPRIV,RIVR,1,NRIVVL,MXRIVR,1,IN,IOUT,
     1          'REACH NO.  LAYER   ROW   COL'//
     2          '     STAGE      CONDUCTANCE     BOTTOM EL.',
     3          RIVAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRRIV,
     &          RIVGROUP)
      END IF
      NRIVER=NNPRIV
C
C1C-----IF THERE ARE ACTIVE RIV PARAMETERS, READ THEM AND SUBSTITUTE
      CALL PRESET('RIV')
      IF(NP.GT.0) THEN
         NREAD=NRIVVL-1
         DO 30 N=1,NP
         CALL UPARLSTSUB(IN,'RIV',IOUTU,'RIV',RIVR,NRIVVL,MXRIVR,NREAD,
     1                MXACTR,NRIVER,5,5,
     2   'REACH NO.  LAYER   ROW   COL'//
     3   '     STAGE      CONDUCTANCE     BOTTOM EL.',RIVAUX,20,NAUX,
     4   IPRRIV, RIVGROUP)
   30    CONTINUE
      END IF
C4------CHECK RIVER HEAD AND MAKE SURE IT IS ABOVE BELL BOTTOM.
      DO 100 L=1,NRIVER
C
C5------GET COLUMN, ROW, AND LAYER OF CELL CONTAINING REACH.
      IL=RIVR(1,L)
      IR=RIVR(2,L)
      IC=RIVR(3,L)
C
C6------IF THE CELL IS EXTERNAL SKIP IT.
      IF(IBOUND(IC,IR,IL).LE.0)GO TO 100
C
C7------SINCE THE CELL IS INTERNAL GET THE RIVER DATA.
      HRIV=RIVR(4,L)
      CRIV=RIVR(5,L)
      RBOT=RIVR(6,L)
      BOT=BOTM(IC,IR,LBOTM(IL))
      DIF=HRIV-RBOT
      IF ( HRIV.LT.BOT ) THEN
          WRITE(LOUT,103)IC,IR,IL
        CALL USTOP(' ')
      END IF
  103 FORMAT('RIVER HEAD SET TO BELOW CELL BOTTOM. MODEL STOPPING. ',
     +                'CELL WITH ERROR (IC,IR,IL): ',3I5) 

  100 CONTINUE
C
C3------PRINT NUMBER OF REACHES IN CURRENT STRESS PERIOD.
        WRITE (IOUT,101) NRIVER
  101 FORMAT(1X,/1X,I6,' RIVER REACHES')
        !
        IF (RIVBUD%BUDGET_GROUPS) THEN
            CALL RIVBUD%RESET()
            CALL RIVBUD%ADD(RIVGROUP(1:NRIVER))
        ELSE
            CALL RIVBUD%ADD( -NRIVER )
        END IF
C
C8------RETURN.
  260 RETURN
      END
      SUBROUTINE GWF2RIV7FM(IGRID)
C     ******************************************************************
C     ADD RIVER TERMS TO RHS AND HCOF
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,HNEW,RHS,HCOF
      USE GWFRIVMODULE, ONLY:NRIVER,RIVR
      DOUBLE PRECISION RRBOT
C     ------------------------------------------------------------------
      CALL SGWF2RIV7PNT(IGRID)
C
C1------IF NRIVER<=0 THERE ARE NO RIVERS. RETURN.
      IF(NRIVER.LE.0)RETURN
C
C2------PROCESS EACH CELL IN THE RIVER LIST.
      DO 100 L=1,NRIVER
C
C3------GET COLUMN, ROW, AND LAYER OF CELL CONTAINING REACH.
      IL=RIVR(1,L)
      IR=RIVR(2,L)
      IC=RIVR(3,L)
C
C4------IF THE CELL IS EXTERNAL SKIP IT.
      IF(IBOUND(IC,IR,IL).LE.0)GO TO 100
C
C5------SINCE THE CELL IS INTERNAL GET THE RIVER DATA.
      HRIV=RIVR(4,L)
      CRIV=RIVR(5,L)
      RBOT=RIVR(6,L)
      RRBOT=RBOT
C
C6------COMPARE AQUIFER HEAD TO BOTTOM OF STREAM BED.
      IF(HNEW(IC,IR,IL).LE.RRBOT)GO TO 96
C
C7------SINCE HEAD>BOTTOM ADD TERMS TO RHS AND HCOF.
      RHS(IC,IR,IL)=RHS(IC,IR,IL)-CRIV*HRIV
      HCOF(IC,IR,IL)=HCOF(IC,IR,IL)-CRIV
      GO TO 100
C
C8------SINCE HEAD<BOTTOM ADD TERM ONLY TO RHS.
   96 RHS(IC,IR,IL)=RHS(IC,IR,IL)-CRIV*(HRIV-RBOT)
  100 CONTINUE
C
C9------RETURN
      RETURN
      END
      SUBROUTINE GWF2RIV7BD(KSTP,KPER,IGRID)
C     ******************************************************************
C     CALCULATE VOLUMETRIC BUDGET FOR RIVERS
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE NUM2STR_INTERFACE, ONLY: NUM2STR
      USE GLOBAL,      ONLY:NCOL,NROW,NLAY,IBOUND,HNEW,BUFF
      USE GWFBASMODULE,ONLY:MSUM,ICBCFL,IAUXSV,DELT,PERTIM,TOTIM,
     1                      VBVL,VBNM,HAS_STARTDATE,DATE_SP
      USE GWFRIVMODULE,ONLY:NRIVER,IRIVCB,RIVR,NRIVVL,RIVAUX,RIVBUD,
     1                      IOUT, RIVDB 
C
      DOUBLE PRECISION HHNEW,CHRIV,RRBOT,CCRIV,RATIN,RATOUT,RRATE
      CHARACTER(16) TEXT
      CHARACTER(19):: DATE
      !DATA TEXT /'   RIVER LEAKAGE'/
C     ------------------------------------------------------------------
      CALL SGWF2RIV7PNT(IGRID)
      !
      IF(RIVDB%IS_OPEN) CALL RIVDB%SIZE_CHECK() !CHECK SIZE EVERY 10 STRESS PERIODS
C
C1------INITIALIZE CELL-BY-CELL FLOW TERM FLAG (IBD) AND
C1------ACCUMULATORS (RATIN AND RATOUT).
      ZERO=0.
      GROUPS: DO IG=1, RIVBUD%NGRP
       TEXT = RIVBUD%GRP(IG)
       TEXT = ADJUSTR(TEXT)
       RATIN=ZERO
       RATOUT=ZERO
       IBD=0
       IF(IRIVCB.LT.0 .AND. ICBCFL.NE.0) IBD=-1
       IF(IRIVCB.GT.0) IBD=ICBCFL
       IBDLBL=0
C
C2------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A LIST, WRITE HEADER.
       IF(IBD.EQ.2) THEN
          NAUX=NRIVVL-7
          IF(IAUXSV.EQ.0) NAUX=0
          CALL UBDSV4(KSTP,KPER,TEXT,NAUX,RIVAUX,IRIVCB,NCOL,NROW,NLAY,
     1           NRIVER,IOUT,DELT,PERTIM,TOTIM,IBOUND)
       END IF
C
C3------CLEAR THE BUFFER.
      DO 50 IL=1,NLAY
      DO 50 IR=1,NROW
      DO 50 IC=1,NCOL
      BUFF(IC,IR,IL)=ZERO
50    CONTINUE
C
C4------IF NO REACHES, SKIP FLOW CALCULATIONS.
      IF(NRIVER.EQ.0)GO TO 200
C
C5------LOOP THROUGH EACH RIVER REACH CALCULATING FLOW.
      FLOW_CALC: DO IDX=1, RIVBUD%DIM(IG)
       L = RIVBUD%INDEX(IG,IDX)
C
C5A-----GET LAYER, ROW & COLUMN OF CELL CONTAINING REACH.
      IL=RIVR(1,L)
      IR=RIVR(2,L)
      IC=RIVR(3,L)
      RATE=ZERO
C
C5B-----IF CELL IS NO-FLOW OR CONSTANT-HEAD MOVE ON TO NEXT REACH.
      IF(IBOUND(IC,IR,IL).LE.0)GO TO 99
C
C5C-----GET RIVER PARAMETERS FROM RIVER LIST.
      HRIV=RIVR(4,L)
      CRIV=RIVR(5,L)
      RBOT=RIVR(6,L)
      RRBOT=RBOT
      HHNEW=HNEW(IC,IR,IL)
C
C5D-----COMPARE HEAD IN AQUIFER TO BOTTOM OF RIVERBED.
      IF(HHNEW.GT.RRBOT) THEN
C
C5E-----AQUIFER HEAD > BOTTOM THEN RATE=CRIV*(HRIV-HNEW).
         CCRIV=CRIV
         CHRIV=CRIV*HRIV
         RRATE=CHRIV - CCRIV*HHNEW
         RATE=RRATE
C
C5F-----AQUIFER HEAD < BOTTOM THEN RATE=CRIV*(HRIV-RBOT).
      ELSE
         RATE=CRIV*(HRIV-RBOT)
         RRATE=RATE
      END IF
      !
      ! PRINT TO DBFILE IF REQUESTED
      IF(RIVDB%IS_OPEN) THEN
            !
            IF(HAS_STARTDATE) THEN
                DATE = DATE_SP(KPER)%TS(KSTP-1)%STR('T')
            ELSE
                DATE='   NaN'
            END IF
            !
            IF(RIVDB%BINARY) THEN
              WRITE(RIVDB%IU)
     +         DATE, KPER, KSTP, DBLE(DELT), DBLE(TOTIM), 
     +         IL,IR,IC,CRIV,HRIV,RBOT,HHNEW,RRATE,TEXT
            ELSE
              WRITE (RIVDB%IU,'(1x,A, 1x,2I8, 2( 1x,A16), 
     +                    3( 1x,I6), 5( 1x,A16), A)')
     +         DATE, KPER, KSTP, NUM2STR(DELT), NUM2STR(TOTIM), 
     +         IL,IR,IC,
     +         NUM2STR(CRIV),NUM2STR(HRIV),NUM2STR(RBOT),NUM2STR(HHNEW),
     +         NUM2STR(RRATE),TEXT
            END IF
      END IF
C
C5G-----PRINT THE INDIVIDUAL RATES IF REQUESTED(IRIVCB<0).
      IF(IBD.LT.0) THEN
           IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61    FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
           WRITE(IOUT,62) L,IL,IR,IC,RATE
   62    FORMAT(1X,'REACH ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',I5,
     1       '   RATE',ES15.6)
         IBDLBL=1
      END IF
C
C5H------ADD RATE TO BUFFER.
      BUFF(IC,IR,IL)=BUFF(IC,IR,IL)+RATE
C
C5I-----SEE IF FLOW IS INTO AQUIFER OR INTO RIVER.
      IF(RATE.LT.ZERO) THEN
C
C5J-----AQUIFER IS DISCHARGING TO RIVER SUBTRACT RATE FROM RATOUT.
        RATOUT=RATOUT-RRATE
      ELSE
C
C5K-----AQUIFER IS RECHARGED FROM RIVER; ADD RATE TO RATIN.
        RATIN=RATIN+RRATE
      END IF
C
C5L-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C5L-----COPY FLOW TO RIVR.
   99 IF(IBD.EQ.2) CALL UBDSVB(IRIVCB,NCOL,NROW,IC,IR,IL,RATE,
     1                  RIVR(:,L),NRIVVL,NAUX,7,IBOUND,NLAY)
      RIVR(NRIVVL,L)=RATE
      END DO FLOW_CALC
C
C6------IF CELL-BY-CELL FLOW WILL BE SAVED AS A 3-D ARRAY,
C6------CALL UBUDSV TO SAVE THEM.
      IF(IBD.EQ.1) CALL UBUDSV(KSTP,KPER,TEXT,IRIVCB,BUFF,NCOL,NROW,
     1                          NLAY,IOUT)
C
C7------MOVE RATES,VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVL(3,MSUM)=RIN
      VBVL(4,MSUM)=ROUT
      VBVL(1,MSUM)=VBVL(1,MSUM)+RIN*DELT
      VBVL(2,MSUM)=VBVL(2,MSUM)+ROUT*DELT
      VBNM(MSUM)=TEXT
C
C8------INCREMENT BUDGET TERM COUNTER.
      MSUM=MSUM+1
      !
      END DO GROUPS
C
C9------RETURN.
      RETURN
      END
      SUBROUTINE GWF2RIV7DA(IGRID)
C  Deallocate RIV MEMORY
      USE GWFRIVMODULE
C
      DEALLOCATE(GWFRIVDAT(IGRID)%NRIVER)
      DEALLOCATE(GWFRIVDAT(IGRID)%MXRIVR)
      DEALLOCATE(GWFRIVDAT(IGRID)%NRIVVL)
      DEALLOCATE(GWFRIVDAT(IGRID)%IRIVCB)
      DEALLOCATE(GWFRIVDAT(IGRID)%IPRRIV)
      DEALLOCATE(GWFRIVDAT(IGRID)%NPRIV )
      DEALLOCATE(GWFRIVDAT(IGRID)%IRIVPB)
      DEALLOCATE(GWFRIVDAT(IGRID)%NNPRIV)
      DEALLOCATE(GWFRIVDAT(IGRID)%RIVAUX)
      DEALLOCATE(GWFRIVDAT(IGRID)%RIVR  )
      DEALLOCATE(GWFRIVDAT(IGRID)%RIVGROUP)
      DEALLOCATE(GWFRIVDAT(IGRID)%IOUT    )
      DEALLOCATE(GWFRIVDAT(IGRID)%LOUT    )
      ! GFORTRAN compiler error work-around for pointer data type FINAL statement
      RIVBUD=>GWFRIVDAT(IGRID)%RIVBUD
      GWFRIVDAT(IGRID)%RIVBUD=>NULL()
      DEALLOCATE(RIVBUD)
      RIVBUD=>NULL()
      !DEALLOCATE(GWFRIVDAT(IGRID)%RIVBUD  )
      !
      RIVDB=>GWFRIVDAT(IGRID)%RIVDB
      GWFRIVDAT(IGRID)%RIVDB=>NULL()
      DEALLOCATE(RIVDB)
      RIVDB=>NULL()
      !DEALLOCATE(GWFRIVDAT(IGRID)%RIVDB   )
C
C NULLIFY THE LOCAL POINTERS
      IF(IGRID.EQ.1)THEN
        NRIVER =>NULL()
        MXRIVR =>NULL()
        NRIVVL =>NULL()
        IRIVCB =>NULL()
        IPRRIV =>NULL()
        NPRIV  =>NULL()
        IRIVPB =>NULL()
        NNPRIV =>NULL()
        RIVAUX =>NULL()
        RIVR   =>NULL()
        RIVBUD  =>NULL()
        RIVGROUP=>NULL()
        IOUT    =>NULL()
        LOUT    =>NULL()
        RIVDB  =>NULL()
      END IF
      RETURN
      END
      SUBROUTINE SGWF2RIV7PNT(IGRID)
C  Change river data to a different grid.
      USE GWFRIVMODULE
C
        NRIVER=>GWFRIVDAT(IGRID)%NRIVER
        MXRIVR=>GWFRIVDAT(IGRID)%MXRIVR
        NRIVVL=>GWFRIVDAT(IGRID)%NRIVVL
        IRIVCB=>GWFRIVDAT(IGRID)%IRIVCB
        IPRRIV=>GWFRIVDAT(IGRID)%IPRRIV
        NPRIV=>GWFRIVDAT(IGRID)%NPRIV
        IRIVPB=>GWFRIVDAT(IGRID)%IRIVPB
        NNPRIV=>GWFRIVDAT(IGRID)%NNPRIV
        RIVAUX=>GWFRIVDAT(IGRID)%RIVAUX
        RIVR=>GWFRIVDAT(IGRID)%RIVR
        RIVBUD  =>GWFRIVDAT(IGRID)%RIVBUD
        RIVGROUP=>GWFRIVDAT(IGRID)%RIVGROUP
        IOUT    =>GWFRIVDAT(IGRID)%IOUT
        LOUT    =>GWFRIVDAT(IGRID)%LOUT
        RIVDB=>GWFRIVDAT(IGRID)%RIVDB
C
      RETURN
      END
      SUBROUTINE SGWF2RIV7PSV(IGRID)
C  Save river data for a grid.
      USE GWFRIVMODULE
C
        GWFRIVDAT(IGRID)%NRIVER=>NRIVER
        GWFRIVDAT(IGRID)%MXRIVR=>MXRIVR
        GWFRIVDAT(IGRID)%NRIVVL=>NRIVVL
        GWFRIVDAT(IGRID)%IRIVCB=>IRIVCB
        GWFRIVDAT(IGRID)%IPRRIV=>IPRRIV
        GWFRIVDAT(IGRID)%NPRIV=>NPRIV
        GWFRIVDAT(IGRID)%IRIVPB=>IRIVPB
        GWFRIVDAT(IGRID)%NNPRIV=>NNPRIV
        GWFRIVDAT(IGRID)%RIVAUX=>RIVAUX
        GWFRIVDAT(IGRID)%RIVR=>RIVR
        GWFRIVDAT(IGRID)%RIVBUD  =>RIVBUD
        GWFRIVDAT(IGRID)%RIVGROUP=>RIVGROUP
        GWFRIVDAT(IGRID)%IOUT    =>IOUT
        GWFRIVDAT(IGRID)%LOUT    =>LOUT
        GWFRIVDAT(IGRID)%RIVDB=>RIVDB
C
      RETURN
      END
!!!      IF(BL%NAME == 'LINEFEED') THEN
!!!         !
!!!         !ALLOCATE RIVFEED VARIABLE AND OPTIONALLY READ IN FEED FILE LOCATIONS
!!!         IF(BL%NLINE>0) THEN
!!!             CALL RIVFEED%INIT(BL)    !=>FEED_ALLOCATE(IN,IOUT,LINE)
!!!             NO_LINEFEED = FALSE
!!!         END IF
!!!      !
!!!      ELSE