      MODULE OBSCHDMODULE
         USE GENERIC_OUTPUT_FILE_INSTRUCTION, ONLY: GENERIC_OUTPUT_FILE
         PRIVATE:: GENERIC_OUTPUT_FILE
         INTEGER, SAVE, POINTER    ::NQCH,NQCCH,NQTCH,IUCHOBSV,IPRT
         INTEGER, SAVE, DIMENSION(:),   POINTER,CONTIGUOUS::NQOBCH
         INTEGER, SAVE, DIMENSION(:),   POINTER,CONTIGUOUS::NQCLCH
         INTEGER, SAVE, DIMENSION(:),   POINTER,CONTIGUOUS::IOBTS
         REAL,    SAVE, DIMENSION(:),   POINTER,CONTIGUOUS::FLWSIM
         REAL,    SAVE, DIMENSION(:),   POINTER,CONTIGUOUS::FLWOBS
         REAL,    SAVE, DIMENSION(:),   POINTER,CONTIGUOUS::TOFF
         REAL,    SAVE, DIMENSION(:),   POINTER,CONTIGUOUS::OTIME
         REAL,    SAVE, DIMENSION(:,:), POINTER,CONTIGUOUS::QCELL
         CHARACTER(12),SAVE,DIMENSION(:),POINTER,CONTIGUOUS::OBSNAM
         LOGICAL,     SAVE,DIMENSION(:),POINTER,CONTIGUOUS::SKIP_OBS
         !INTEGER, SAVE,POINTER ::FN_PRN_ALL,FN_PRN
         TYPE(GENERIC_OUTPUT_FILE), SAVE,POINTER:: FN_PRN, FN_PRN_ALL
      TYPE OBSCHDTYPE
         INTEGER,            POINTER ::NQCH,NQCCH,NQTCH,IUCHOBSV,IPRT
         INTEGER,     DIMENSION(:),  POINTER,CONTIGUOUS::NQOBCH
         INTEGER,     DIMENSION(:),  POINTER,CONTIGUOUS::NQCLCH
         INTEGER,     DIMENSION(:),  POINTER,CONTIGUOUS::IOBTS
         REAL,        DIMENSION(:),  POINTER,CONTIGUOUS::FLWSIM
         REAL,        DIMENSION(:),  POINTER,CONTIGUOUS::FLWOBS
         REAL,        DIMENSION(:),  POINTER,CONTIGUOUS::TOFF
         REAL,        DIMENSION(:),  POINTER,CONTIGUOUS::OTIME
         REAL,        DIMENSION(:,:),POINTER,CONTIGUOUS::QCELL
         CHARACTER(12),DIMENSION(:),  POINTER,CONTIGUOUS::OBSNAM
         LOGICAL,  DIMENSION(:),     POINTER,CONTIGUOUS::SKIP_OBS
         !INTEGER,            POINTER ::FN_PRN_ALL,FN_PRN
         TYPE(GENERIC_OUTPUT_FILE),POINTER:: FN_PRN, FN_PRN_ALL
      END TYPE
      TYPE(OBSCHDTYPE), SAVE  ::OBSCHDDAT(10)
      END MODULE OBSCHDMODULE



      SUBROUTINE OBS2CHD7AR(IUCHOB,IGRID)
C     ******************************************************************
C     ALLOCATE AND READ DATA FOR FLOW OBSERVATIONS AT CONSTANT-HEAD
C     BOUNDARY CELLS
C     ******************************************************************
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY: NCOL,NROW,NLAY,NPER,NSTP,PERLEN,TSMULT,ISSFLG,
     1                  IOUT,ITRSS
      USE OBSCHDMODULE
C
      CHARACTER(768):: LINE
      CHARACTER(10)::DATE
      CHARACTER(13)::DYEAR
C     ------------------------------------------------------------------
      ALLOCATE(NQCH,NQTCH,NQCCH,IUCHOBSV,IPRT)
      ALLOCATE(FN_PRN_ALL,FN_PRN)
C
C1------INITIALIZE VARIABLEA.
      ZERO=0.0
      IERR=0
      NT=0
      NC=0
      !FN_PRN_ALL=0
      !FN_PRN=0
C
C2------IDENTIFY PROCESS
        WRITE(IOUT,14) IUCHOB
   14 FORMAT(/,' OBS2CHD7 -- CONSTANT-HEAD BOUNDARY FLOW OBSERVATIONS',
     &    /,' VERSION OWHM       INPUT READ FROM UNIT ',I3)
C
C3------ITEM 1
      CALL URDCOM(IUCHOB,IOUT,LINE)
      ! CHECK FOR POTENTIAL KEYWORDS
      LLOC = 1
      DO
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,IDUM,DUM,IOUT,IUCHOB)
         IF    (LINE(ISTART:ISTOP)=='TIME_STEP_PRINT') THEN
             CALL FN_PRN%OPEN(LINE,LLOC,IOUT,IUCHOB,NOBINARY=.TRUE.)
             !CALL URWORD(LINE,LLOC,ISTART,ISTOP,0,IDUM,DUM,IOUT,IUCHOB)
             !READ(LINE(ISTART:ISTOP),*,IOSTAT=IERR) FN_PRN
             !IF(IERR.NE.0) THEN
             !    OPEN(NEWUNIT=FN_PRN,    FILE=LINE(ISTART:ISTOP),
     +       !        ACTION='WRITE',POSITION='REWIND', STATUS='REPLACE')
             !END IF
            CALL URDCOM(IUCHOB,IOUT,LINE)
         ELSEIF(LINE(ISTART:ISTOP)=='TIME_STEP_PRINT_ALL') THEN
             CALL FN_PRN_ALL%OPEN(LINE,LLOC,IOUT,IUCHOB,NOBINARY=.TRUE.,
     +                            NO_INTERNAL=.TRUE.)
             !CALL URWORD(LINE,LLOC,ISTART,ISTOP,0,IDUM,DUM,IOUT,IUCHOB)
             !READ(LINE(ISTART:ISTOP),*,IOSTAT=IERR) FN_PRN_ALL
             !IF(IERR.NE.0) THEN
             !    OPEN(NEWUNIT=FN_PRN_ALL,FILE=LINE(ISTART:ISTOP),
     +       !        ACTION='WRITE',POSITION='REWIND', STATUS='REPLACE')
             !END IF
            CALL URDCOM(IUCHOB,IOUT,LINE)
         ELSE
             EXIT
         END IF
      END DO
      !
      LLOC = 1
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NQCH,DUM,IOUT,IUCHOB)
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NQCCH,DUM,IOUT,IUCHOB)
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NQTCH,DUM,IOUT,IUCHOB)
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IUCHOBSV,DUM,IOUT,IUCHOB)
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,IDUM,DUM,IOUT,IUCHOB)
      IPRT=1
      IF(LINE(ISTART:ISTOP).EQ.'NOPRINT' .OR.
     +   LINE(ISTART:ISTOP).EQ.'NO_PRINT') THEN
        IPRT=0
        WRITE(IOUT,*) 'NOPRINT option for CONSTANT-HEAD OBSERVATIONS'
      END IF
        WRITE (IOUT,17) NQCH, NQCCH, NQTCH
   17 FORMAT (/,
     &    ' NUMBER OF FLOW-OBSERVATION CONSTANT-HEAD-CELL GROUPS:',I5,/,
     &    '   NUMBER OF CELLS IN CONSTANT-HEAD-CELL GROUPS......:',I5,/,
     &    '   NUMBER OF CONSTANT-HEAD-CELL FLOWS................:',I5)
      IF(NQTCH.LE.0) THEN
           WRITE(IOUT,*) ' NQTCH LESS THAN OR EQUAL TO 0'
         CALL USTOP(' ')
      END IF
      IF(IUCHOBSV.GT.0) THEN
           WRITE(IOUT,21) IUCHOBSV
   21    FORMAT(1X,
     1      'CH OBSERVATIONS WILL BE SAVED ON UNIT...............:',I5)
      ELSE
           WRITE(IOUT,22)
   22    FORMAT(1X,'CH OBSERVATIONS WILL NOT BE SAVED IN A FILE')
      END IF
C
C4------ALLOCATE ARRAYS
      ALLOCATE(SKIP_OBS(NQCH), SOURCE=.FALSE.)                          !seb
      ALLOCATE (NQOBCH(NQCH))
      ALLOCATE (NQCLCH(NQCH))
      ALLOCATE (IOBTS(NQTCH))
      ALLOCATE (FLWSIM(NQTCH))
      ALLOCATE (FLWOBS(NQTCH))
      ALLOCATE (TOFF(NQTCH))
      ALLOCATE (OTIME(NQTCH))
      ALLOCATE (QCELL(4,NQCCH))
      ALLOCATE (OBSNAM(NQTCH))
      DO 19 N=1,NQTCH
      OTIME(N)=ZERO
      FLWSIM(N)=ZERO
   19 CONTINUE
C
C5------READ AND WRITE TIME-OFFSET MULTIPLIER FOR FLOW-OBSERVATION TIMES
      READ(IUCHOB,*) TOMULTCH
      IF(IPRT.NE.0) THEN
        WRITE (IOUT,520) TOMULTCH
      ENDIF
  520 FORMAT (/,' OBSERVED CONSTANT-HEAD-CELL FLOW DATA',/,
     &' -- TIME OFFSETS ARE MULTIPLIED BY: ',G12.5)
C
C6------LOOP THROUGH CELL GROUPS.
      DO 120 IQ = 1,NQCH
C
C7------READ ITEM 3
        READ (IUCHOB,*) NQOBCH(IQ), NQCLCH(IQ)
        IF(IPRT.NE.0) THEN
          WRITE (IOUT,525) IQ, 'CHD', NQCLCH(IQ), NQOBCH(IQ)
        ENDIF
  525   FORMAT (/,'   GROUP NUMBER: ',I3,'   BOUNDARY TYPE: ',A,
     &         '   NUMBER OF CELLS IN GROUP: ',I5,/,
     &         '   NUMBER OF FLOW OBSERVATIONS: ',I5,//,
     &         40X,'OBSERVED',/,
     &         20X,'REFER.',12X,'BOUNDARY FLOW',/,
     &      7X,'OBSERVATION',2X,'STRESS',4X,'TIME',5X,'GAIN (-) OR',/,
     &         2X,'OBS#    NAME',6X,'PERIOD   OFFSET',5X,'LOSS (+)')
C
C8------SET FLAG FOR SETTING ALL FACTORS TO 1
        IFCTFLG = 0
        IF (NQCLCH(IQ).LT.0) THEN
          IFCTFLG = 1
          NQCLCH(IQ) = -NQCLCH(IQ)
        ENDIF
C
C9------READ TIME STEPS, MEASURED FLOWS, AND WEIGHTS.
        NT1 = 1 + NT
        NT2 = NQOBCH(IQ) + NT
        DO 30 N = NT1, NT2
C
C10-----READ ITEM 4
          READ (IUCHOB,*) OBSNAM(N), IREFSP, TOFFSET, FLWOBS(N)
          IF(IPRT.NE.0) THEN
            WRITE (IOUT,535) N, OBSNAM(N), IREFSP, TOFFSET, FLWOBS(N)
          ENDIF
  535     FORMAT(1X,I5,1X,A12,2X,I4,2X,G11.4,1X,G11.4)
          CALL UOBSTI(OBSNAM(N),IOUT,ISSFLG,ITRSS,NPER,NSTP,IREFSP,
     &                IOBTS(N),PERLEN,TOFF(N),TOFFSET,TOMULTCH,TSMULT,1,
     &                OTIME(N),SKIP_OBS(N),DATE,DYEAR)
   30   CONTINUE
C
C11-----READ LAYER, ROW, COLUMN, AND FACTOR (ITEM 5)
        NC1 = NC + 1
        NC2 = NC + NQCLCH(IQ)
        IF(IPRT.NE.0) THEN
          WRITE (IOUT,540)
        ENDIF
  540   FORMAT (/,'       LAYER  ROW  COLUMN    FACTOR')
        DO 40 L = NC1, NC2
          READ (IUCHOB,*) (QCELL(I,L),I=1,4)
          IF(QCELL(4,L).EQ.0. .OR. IFCTFLG.EQ.1) QCELL(4,L) = 1.
          IF(IPRT.NE.0) THEN
            WRITE (IOUT,550) (QCELL(I,L),I=1,4)
          ENDIF
  550     FORMAT (4X,F8.0,F6.0,F7.0,F9.2)
          K = QCELL(1,L)
          I = QCELL(2,L)
          J = QCELL(3,L)
          IF (K.LE.0 .OR. K.GT.NLAY .OR .J.LE.0 .OR. J.GT.NCOL .OR.
     &        I.LE.0 .OR. I.GT.NROW) THEN
              WRITE (IOUT,590)
  590       FORMAT (/,' ROW OR COLUMN NUMBER INVALID',
     &        ' -- STOP EXECUTION (OBS2CHD7AR)',/)
            IERR = 1
          ENDIF
   40   CONTINUE
C
C12-----UPDATE COUNTERS.
        NC = NC2
        NT = NT2
  120 CONTINUE
C
C13-----STOP IF THERE WERE ANY ERRORS WHILE READING.
      IF (IERR.GT.0) THEN
          WRITE(IOUT,620)
  620   FORMAT (/,' ERROR:  SEE ABOVE FOR ERROR MESSAGE AND "STOP',
     &        ' EXECUTION" (OBS2CHD7AR)')
        CALL USTOP(' ')
      ENDIF
C
C14-----RETURN.
      CALL SOBS2CHD7PSV(IGRID)
      RETURN
      END
      SUBROUTINE OBS2CHD7SE(KKPER,IUNITUPW,IGRID)
C     ******************************************************************
C     CALCULATE SIMULATED EQUIVALENTS TO OBSERVED CONSTANT-HEAD FLOWS
C     ******************************************************************
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,    ONLY:IBOUND,IOUT
      USE OBSBASMODULE,ONLY:ITS
      USE OBSCHDMODULE
C
      DOUBLE PRECISION RATE
      INTEGER KKPER,IUNITUPW,IGRID
      LOGICAL:: NO_UPW
      NO_UPW = IUNITUPW == 0
C     ------------------------------------------------------------------
      CALL SGWF2CHD7PNT(IGRID)
      CALL SOBS2CHD7PNT(IGRID)
C
C-------PRINT OUT OPTIONAL HEADER FOR PRINTING AT TIME STEP
      IF(FN_PRN%IS_OPEN.AND.ITS==1) THEN
        WRITE(FN_PRN%IU,17)
   17   FORMAT(1X,/,1X,'CONSTANT HEAD FLOW OBSERVATIONS',/,
     1  1X,'OBSERVATION     OBSERVED      SIMULATED',/
     2  1X,'  NAME            VALUE         VALUE      DIFFERENCE',/
     3  1X,'-------------------------------------------------------')
      END IF
C
C1------INITIALIZE VARIABLES
      ZERO = 0.0
      NC = 0
      NT1 = 1
C
C2------LOOP THROUGH BOUNDARY FLOW CELL GROUPS
      DO 60 IQ = 1, NQCH
        NT2 = NT1 + NQOBCH(IQ) - 1
C
C3--------LOOP THROUGH THE OBSERVATION TIMES FOR THIS CELL GROUP.
        DO 40 NT = NT1, NT2
C
C4--------WAS THERE A MEASUREMENT AT THIS BOUNDARY THIS TIME STEP?
          IF(SKIP_OBS(NT)) THEN
              WRITE (IOUT,490) NT, OBSNAM(NT)
  490         FORMAT (/,' CHD  OBS#',I5,', ID ',A,' IS BEING SKIPPED',
     &          ' DUE TO NOT BEING WITHIN SIMULATED TIME (OBS2CHD7SE)')
              CYCLE
          END IF
          IF (IOBTS(NT).EQ.ITS .OR.
     &        (IOBTS(NT).EQ.ITS-1.AND.TOFF(NT).GT.ZERO)) THEN
C
C5------YES -- LOOP THROUGH CELLS.
            NC1 = NC + 1
            NC2 = NC + NQCLCH(IQ)
            DO 30 N = NC1, NC2
              K = QCELL(1,N)
              I = QCELL(2,N)
              J = QCELL(3,N)
              IF (IBOUND(J,I,K).GE.0) THEN
                  WRITE(IOUT,500) K,I,J,KKPER
  500           FORMAT(/,
     &' *** ERROR: CONSTANT-HEAD FLOW OBSERVATION SPECIFIED FOR CELL (',
     &I3,',',I5,',',I5,'),',/,
     &12X,'BUT THIS CELL IS NOT CONSTANT-HEAD IN STRESS PERIOD ',I4,/
     &12X,'-- STOP EXECUTION (OBS2CHD7SE)')
                CALL USTOP(' ')
              ENDIF
C
C6------CALL SUBROUTINE TO CALCULATE CONSTANT-HEAD FLOW FOR CELL
              CALL SOBS2CHD7FFLW(J,I,K,RATE,NO_UPW)
C
C7------SUM VALUES FROM INDIVIDUAL CELLS.
C7------CALCULATE FACTOR FOR TEMPORAL INTERPOLATION
   20         FACT = 1.0
              IF (TOFF(NT).GT.ZERO) THEN
                IF (IOBTS(NT).EQ.ITS) FACT = 1. - TOFF(NT)
                IF (IOBTS(NT).EQ.ITS-1) FACT = TOFF(NT)
              ENDIF
C
C8------ACCUMULATE FLOWS FOR THE SIMULATED OBSERVATION.
              FLWSIM(NT) = FLWSIM(NT) + RATE*FACT*QCELL(4,N)
C
Cx------END OF LOOP FOR CELLS IN ONE GROUP.
   30       CONTINUE
C
          ENDIF
C
Cx------END OF LOOP FOR OBSERVATION TIMES FOR ONE GROUP
   40   CONTINUE
C
C10-----UPDATE CELL AND TIME COUNTERS 
        NC = NC + NQCLCH(IQ)
        NT1 = NT2 + 1
C
Cx------END OF LOOP FOR CELL GROUPS.
   60 CONTINUE
C
      IF(FN_PRN_ALL%IS_OPEN) THEN
         CALL UOBSSV(FN_PRN_ALL%IU,NQTCH,FLWSIM,FLWOBS,
     1                              OBSNAM,0)
      END IF
C11-----RETURN.
      RETURN
      END
      SUBROUTINE SOBS2CHD7FFLW(J,I,K,RATE,NO_UPW)
C     ******************************************************************
C     CALCULATE CONSTANT-HEAD BOUNDARY FLOW FOR A GIVEN CELL
C     ******************************************************************
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,HNEW,CR,CC,CV,BOTM,NBOTM,
     1                       NCOL,NROW,NLAY,LAYHDT,LBOTM
      USE GWFBASMODULE, ONLY:ICHFLG
      USE GWFUPWMODULE,ONLY:IUPWCB, Sn, LAYTYPUPW
      USE GWFNWTMODULE,ONLY:Icell, Closezero
C
      DOUBLE PRECISION HD,X1,X2,X3,X4,X5,X6,RATE
      LOGICAL:: NO_UPW
C     ------------------------------------------------------------------
C
C6------CLEAR VALUES FOR FLOW RATE THROUGH EACH FACE OF CELL.
      ZERO=0.
      X1=ZERO
      X2=ZERO
      X3=ZERO
      X4=ZERO
      X5=ZERO
      X6=ZERO
      iltyp = 0
      IF ( .not. NO_UPW ) iltyp = LAYTYPUPW(K)
C
C7------CALCULATE FLOW THROUGH THE LEFT FACE.
C7------COMMENTS A-C APPEAR ONLY IN THE SECTION HEADED BY COMMENT 7,
C7------BUT THEY APPLY IN A SIMILAR MANNER TO SECTIONS 8-12.
C
C7A-----IF THERE IS NO FLOW TO CALCULATE THROUGH THIS FACE, THEN GO ON
C7A-----TO NEXT FACE.  NO FLOW OCCURS AT THE EDGE OF THE GRID, TO AN
C7A-----ADJACENT NO-FLOW CELL, OR TO AN ADJACENT CONSTANT-HEAD CELL
C7A-----WHEN ICHFLG IS 0.
      IF(J.EQ.1) GO TO 30
      IF(IBOUND(J-1,I,K).EQ.0) GO TO 30
      IF(ICHFLG.EQ.0 .AND. IBOUND(J-1,I,K).LT.0) GO TO 30
C
C7B-----CALCULATE FLOW THROUGH THIS FACE INTO THE ADJACENT CELL.
      HDIFF=HNEW(J,I,K)-HNEW(J-1,I,K)
      IF(NO_UPW) THEN
         X1=HDIFF*CR(J-1,I,K)
      ELSEIF ( HDIFF.GE.-Closezero ) THEN
        IF ( iltyp.GT.0 ) THEN
          THICK = dble(BOTM(J,I,LBOTM(K)-1)) - dble(BOTM(J,I,LBOTM(K)))
          ij = Icell(J,I,K)
          X1=HDIFF*CR(J-1,I,K)*THICK*Sn(ij)
        ELSE
          X1=HDIFF*CR(J-1,I,K)
        END IF
      ELSE
        IF ( iltyp.GT.0 ) THEN
          THICK = dble(BOTM(J-1,I,LBOTM(K)-1)) - 
     +            dble(BOTM(J-1,I,LBOTM(K)))
          ij = Icell(J-1,I,K)
          X1=HDIFF*CR(J-1,I,K)*THICK*Sn(ij)
        ELSE
          X1=HDIFF*CR(J-1,I,K)
        END IF
      END IF
      
C
C8------CALCULATE FLOW THROUGH THE RIGHT FACE.
   30 IF(J.EQ.NCOL) GO TO 60
      IF(IBOUND(J+1,I,K).EQ.0) GO TO 60
      IF(ICHFLG.EQ.0 .AND. IBOUND(J+1,I,K).LT.0) GO TO 60
      HDIFF=HNEW(J,I,K)-HNEW(J+1,I,K)
      IF(NO_UPW) THEN
         X2=HDIFF*CR(J,I,K)
      ELSEIF ( HDIFF.GE.-Closezero ) THEN
        IF ( iltyp.GT.0 ) THEN
          THICK = dble(BOTM(J,I,LBOTM(K)-1)) - dble(BOTM(J,I,LBOTM(K)))
          ij = Icell(J,I,K)
          X2=HDIFF*CR(J,I,K)*THICK*Sn(ij)
        ELSE 
          X2=HDIFF*CR(J,I,K)
        END IF
      ELSE
        IF ( iltyp.GT.0 ) THEN
          THICK = dble(BOTM(J+1,I,LBOTM(K)-1)) - 
     +            dble(BOTM(J+1,I,LBOTM(K)))
          ij = Icell(J+1,I,K)
          X2=HDIFF*CR(J,I,K)*THICK*Sn(ij)
        ELSE
          X2=HDIFF*CR(J,I,K)
        END IF
      END IF
C
C9------CALCULATE FLOW THROUGH THE BACK FACE.
   60 IF(I.EQ.1) GO TO 90
      IF (IBOUND(J,I-1,K).EQ.0) GO TO 90
      IF(ICHFLG.EQ.0 .AND. IBOUND(J,I-1,K).LT.0) GO TO 90
      HDIFF=HNEW(J,I,K)-HNEW(J,I-1,K)
      IF(NO_UPW) THEN
         X3=HDIFF*CC(J,I-1,K)
      ELSEIF ( HDIFF.GE.-Closezero ) THEN
        IF ( iltyp.GT.0 ) THEN
          THICK = dble(BOTM(J,I,LBOTM(K)-1)) - dble(BOTM(J,I,LBOTM(K)))
          ij =  Icell(J,I,K)
          X3=HDIFF*CC(J,I-1,K)*THICK*Sn(ij)
        ELSE
          X3=HDIFF*CC(J,I-1,K)
        END IF
      ELSE
        IF ( iltyp.GT.0 ) THEN
          THICK = dble(BOTM(J,I-1,LBOTM(K)-1)) - 
     +            dble(BOTM(J,I-1,LBOTM(K)))
          ij =  Icell(J,I-1,K)
          X3=HDIFF*CC(J,I-1,K)*THICK*Sn(ij)
        ELSE
          X3=HDIFF*CC(J,I-1,K)
        END IF
      END IF
C
C10-----CALCULATE FLOW THROUGH THE FRONT FACE.
   90 IF(I.EQ.NROW) GO TO 120
      IF(IBOUND(J,I+1,K).EQ.0) GO TO 120
      IF(ICHFLG.EQ.0 .AND. IBOUND(J,I+1,K).LT.0) GO TO 120
      HDIFF=HNEW(J,I,K)-HNEW(J,I+1,K)
      IF(NO_UPW) THEN
         X4=HDIFF*CC(J,I,K)
      ELSEIF ( HDIFF.GE.-Closezero ) THEN
        IF ( iltyp.GT.0 ) THEN
          THICK = dble(BOTM(J,I,LBOTM(K)-1)) - dble(BOTM(J,I,LBOTM(K)))
          ij = Icell(J,I,K)
          X4=HDIFF*CC(J,I,K)*THICK*Sn(ij)
        ELSE
          X4=HDIFF*CC(J,I,K)
        END IF
      ELSE
        IF ( iltyp.GT.0 ) THEN
          THICK = dble(BOTM(J,I+1,LBOTM(K)-1)) - 
     +            dble(BOTM(J,I+1,LBOTM(K)))
          ij = Icell(J,I+1,K)
          X4=HDIFF*CC(J,I,K)*THICK*Sn(ij)
        ELSE
          X4=HDIFF*CC(J,I,K)
        END IF
      END IF
C
C11-----CALCULATE FLOW THROUGH THE UPPER FACE.
  120 IF(K.EQ.1) GO TO 150
      IF (IBOUND(J,I,K-1).EQ.0) GO TO 150
      IF(ICHFLG.EQ.0 .AND. IBOUND(J,I,K-1).LT.0) GO TO 150
      HD=HNEW(J,I,K)
      IF(NO_UPW) THEN
         IF(LAYHDT(K).EQ.0) GO TO 122
         TMP=HD
         TOP=BOTM(J,I,LBOTM(K)-1)
         IF(TMP.LT.TOP) HD=TOP
  122    HDIFF=HD-HNEW(J,I,K-1)
      ELSE
         HDIFF=HD-HNEW(J,I,K-1)
      END IF
      X5=HDIFF*CV(J,I,K-1)
C
C12-----CALCULATE FLOW THROUGH THE LOWER FACE.
  150 IF(K.EQ.NLAY) GO TO 180
      IF(IBOUND(J,I,K+1).EQ.0) GO TO 180
      IF(ICHFLG.EQ.0 .AND. IBOUND(J,I,K+1).LT.0) GO TO 180
      HD=HNEW(J,I,K+1)
      IF(NO_UPW) THEN
         IF(LAYHDT(K+1).EQ.0) GO TO 152
         TMP=HD
         TOP=BOTM(J,I,LBOTM(K+1)-1)
         IF(TMP.LT.TOP) HD=TOP
  152    HDIFF=HNEW(J,I,K)-HD
      ELSE
         HDIFF=HNEW(J,I,K)-HD
         END IF
      X6=HDIFF*CV(J,I,K)
C
C13-----SUM THE FLOWS THROUGH SIX FACES OF CONSTANT HEAD CELL
 180  RATE=X1+X2+X3+X4+X5+X6
C
C-----RETURN
      RETURN
      END
      SUBROUTINE OBS2CHD7OT(IGRID)
C     ******************************************************************
C     WRITE ALL OBSERVATIONS TO LISTING FILE.
C     ******************************************************************
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY: IOUT
      USE OBSCHDMODULE
      DOUBLE PRECISION SQ,SUMSQ
C     ------------------------------------------------------------------
      CALL SOBS2CHD7PNT(IGRID)
C
C1------WRITE OBSERVATIONS TO LISTING FILE.
      IF(IPRT.NE.0) THEN
        WRITE(IOUT,17)
      ENDIF
   17 FORMAT(1X,/,1X,'CONSTANT HEAD FLOW OBSERVATIONS',/,
     1  1X,'OBSERVATION     OBSERVED      SIMULATED',/
     2  1X,'  NAME            VALUE         VALUE      DIFFERENCE',/
     3  1X,'-------------------------------------------------------')
      SUMSQ=0.
      DO 100 N=1,NQTCH
      DIFF=FLWOBS(N)-FLWSIM(N)
      SQ=DIFF*DIFF
      SUMSQ=SUMSQ+SQ
      IF(IPRT.NE.0) THEN
        WRITE(IOUT,27) OBSNAM(N),FLWOBS(N),FLWSIM(N),DIFF
      ENDIF
   27 FORMAT(1X,A,1P,3G14.6)
  100 CONTINUE
        WRITE(IOUT,28) SUMSQ
   28 FORMAT(1X,/,1X,'SUM OF SQUARED DIFFERENCE:',ES15.5)
C
C2------WRITE OBSERVATIONS TO SEPARATE FILE.
      IF(IUCHOBSV.GT.0) CALL UOBSSV(IUCHOBSV,NQTCH,FLWSIM,FLWOBS,
     1                              OBSNAM,0)
C
C3------RETURN.
      RETURN
      END
      SUBROUTINE OBS2CHD7DA(IGRID)
C  Deallocate OBSCHD memory
      USE OBSCHDMODULE
C
      DEALLOCATE(OBSCHDDAT(IGRID)%NQCH    )
      DEALLOCATE(OBSCHDDAT(IGRID)%NQTCH   )
      DEALLOCATE(OBSCHDDAT(IGRID)%NQCCH   )
      DEALLOCATE(OBSCHDDAT(IGRID)%IUCHOBSV)
      DEALLOCATE(OBSCHDDAT(IGRID)%IPRT)
      DEALLOCATE(OBSCHDDAT(IGRID)%NQOBCH  )
      DEALLOCATE(OBSCHDDAT(IGRID)%NQCLCH  )
      DEALLOCATE(OBSCHDDAT(IGRID)%IOBTS   )
      DEALLOCATE(OBSCHDDAT(IGRID)%FLWSIM  )
      DEALLOCATE(OBSCHDDAT(IGRID)%FLWOBS  )
      DEALLOCATE(OBSCHDDAT(IGRID)%TOFF    )
      DEALLOCATE(OBSCHDDAT(IGRID)%OTIME   )
      DEALLOCATE(OBSCHDDAT(IGRID)%QCELL   )
      DEALLOCATE(OBSCHDDAT(IGRID)%OBSNAM  )
      DEALLOCATE(OBSCHDDAT(IGRID)%SKIP_OBS)
      !
      FN_PRN_ALL=>OBSCHDDAT(IGRID)%FN_PRN_ALL
      OBSCHDDAT(IGRID)%FN_PRN_ALL=>NULL()
      DEALLOCATE(FN_PRN_ALL)
      FN_PRN_ALL=>NULL()
      !
      FN_PRN=>OBSCHDDAT(IGRID)%FN_PRN
      OBSCHDDAT(IGRID)%FN_PRN=>NULL()
      DEALLOCATE(FN_PRN)
      FN_PRN=>NULL()
      !DEALLOCATE(OBSCHDDAT(IGRID)%FN_PRN_ALL)
      !DEALLOCATE(OBSCHDDAT(IGRID)%FN_PRN)
C
C Nullify the local pointers
      IF(IGRID.EQ.1)THEN
        NQCH    =>NULL()
        NQTCH   =>NULL()
        NQCCH   =>NULL()
        IUCHOBSV=>NULL()
        IPRT    =>NULL()
        NQOBCH  =>NULL()
        NQCLCH  =>NULL()
        IOBTS   =>NULL()
        FLWSIM  =>NULL()
        FLWOBS  =>NULL()
        TOFF    =>NULL()
        OTIME   =>NULL()
        QCELL   =>NULL()
        OBSNAM  =>NULL()
        SKIP_OBS=>NULL()
        FN_PRN_ALL=>NULL()
        FN_PRN=>NULL()
      END IF
      RETURN
      END
      SUBROUTINE SOBS2CHD7PNT(IGRID)
C  Change OBSCHD data to a different grid.
      USE OBSCHDMODULE
C
      NQCH=>OBSCHDDAT(IGRID)%NQCH
      NQTCH=>OBSCHDDAT(IGRID)%NQTCH
      NQCCH=>OBSCHDDAT(IGRID)%NQCCH
      IUCHOBSV=>OBSCHDDAT(IGRID)%IUCHOBSV
      IPRT=>OBSCHDDAT(IGRID)%IPRT
      NQOBCH=>OBSCHDDAT(IGRID)%NQOBCH
      NQCLCH=>OBSCHDDAT(IGRID)%NQCLCH
      IOBTS=>OBSCHDDAT(IGRID)%IOBTS
      FLWSIM=>OBSCHDDAT(IGRID)%FLWSIM
      FLWOBS=>OBSCHDDAT(IGRID)%FLWOBS
      TOFF=>OBSCHDDAT(IGRID)%TOFF
      OTIME=>OBSCHDDAT(IGRID)%OTIME
      QCELL=>OBSCHDDAT(IGRID)%QCELL
      OBSNAM=>OBSCHDDAT(IGRID)%OBSNAM
      SKIP_OBS=>OBSCHDDAT(IGRID)%SKIP_OBS
      FN_PRN_ALL=>OBSCHDDAT(IGRID)%FN_PRN_ALL
      FN_PRN    =>OBSCHDDAT(IGRID)%FN_PRN
C
      RETURN
      END
      SUBROUTINE SOBS2CHD7PSV(IGRID)
C  Save OBSCHD data for a grid.
      USE OBSCHDMODULE
C
      OBSCHDDAT(IGRID)%NQCH=>NQCH
      OBSCHDDAT(IGRID)%NQTCH=>NQTCH
      OBSCHDDAT(IGRID)%NQCCH=>NQCCH
      OBSCHDDAT(IGRID)%IUCHOBSV=>IUCHOBSV
      OBSCHDDAT(IGRID)%IPRT=>IPRT
      OBSCHDDAT(IGRID)%NQOBCH=>NQOBCH
      OBSCHDDAT(IGRID)%NQCLCH=>NQCLCH
      OBSCHDDAT(IGRID)%IOBTS=>IOBTS
      OBSCHDDAT(IGRID)%FLWSIM=>FLWSIM
      OBSCHDDAT(IGRID)%FLWOBS=>FLWOBS
      OBSCHDDAT(IGRID)%TOFF=>TOFF
      OBSCHDDAT(IGRID)%OTIME=>OTIME
      OBSCHDDAT(IGRID)%QCELL=>QCELL
      OBSCHDDAT(IGRID)%OBSNAM=>OBSNAM
      OBSCHDDAT(IGRID)%SKIP_OBS=>SKIP_OBS
      OBSCHDDAT(IGRID)%FN_PRN_ALL=>FN_PRN_ALL
      OBSCHDDAT(IGRID)%FN_PRN    =>FN_PRN
C
      RETURN
      END
