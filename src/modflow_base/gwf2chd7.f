      MODULE GWFCHDMODULE
        USE BUDGET_GROUP_INTERFACE, ONLY: BUDGET_GROUP
        PRIVATE:: BUDGET_GROUP
        !
        INTEGER,SAVE,POINTER:: IOUT, LOUT
        INTEGER,SAVE,POINTER  ::NCHDS,MXCHD,NCHDVL,IPRCHD
        INTEGER,SAVE,POINTER  ::NPCHD,ICHDPB,NNPCHD
        CHARACTER(LEN=16),SAVE,DIMENSION(:),  POINTER,CONTIGUOUS::CHDAUX
        REAL,             SAVE,DIMENSION(:,:),POINTER,CONTIGUOUS::CHDS
      TYPE GWFCHDTYPE
        INTEGER,POINTER:: IOUT, LOUT
        INTEGER,POINTER  ::NCHDS,MXCHD,NCHDVL,IPRCHD
        INTEGER,POINTER  ::NPCHD,ICHDPB,NNPCHD
        CHARACTER(LEN=16), DIMENSION(:),   POINTER,CONTIGUOUS::CHDAUX
        REAL,              DIMENSION(:,:), POINTER,CONTIGUOUS::CHDS
      END TYPE
      TYPE(GWFCHDTYPE),SAVE   ::GWFCHDDAT(10)
      END MODULE

      SUBROUTINE GWF2CHD7AR(IN,IGRID)
C     ******************************************************************
C     ALLOCATE ARRAY STORAGE FOR TIME-VARIANT SPECIFIED-HEAD CELLS AND
C     READ NAMED PARAMETER DEFINITIONS
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE UTIL_INTERFACE, ONLY: READ_TO_DATA
      USE GLOBAL,         ONLY:LIST_UNIT=>IOUT,NCOL,NROW,NLAY,IFREFM
      USE GWFCHDMODULE,   ONLY:NCHDS,MXCHD,NCHDVL,IPRCHD,NPCHD,ICHDPB,
     1                         NNPCHD,CHDAUX,CHDS,IOUT,LOUT
      CHARACTER*700 LINE
      CHARACTER(20),DIMENSION(1):: CHDGROUP
C     ------------------------------------------------------------------
      CHDGROUP='NOGROUP'
      ALLOCATE(NCHDS,MXCHD,NCHDVL,IPRCHD)
      ALLOCATE(NPCHD,ICHDPB,NNPCHD)
      !
      ALLOCATE(IOUT,LOUT)
      LOUT=LIST_UNIT
      IOUT=LIST_UNIT
      CALL READ_TO_DATA(LINE,IN,LOUT,LOUT)
      !
C
C1------IDENTIFY OPTION AND INITIALIZE # OF SPECIFIED-HEAD CELLS
        WRITE(IOUT,1)IN
    1 FORMAT(1X,/1X,'CHD -- TIME-VARIANT SPECIFIED-HEAD OPTION,',
     1  ' VERSION 7, 5/2/2005',/1X,'INPUT READ FROM UNIT ',I4)
      NCHDS=0
      NNPCHD=0
C
C2------READ AND PRINT MXCHD (MAXIMUM NUMBER OF SPECIFIED-HEAD
C2------CELLS TO BE SPECIFIED EACH STRESS PERIOD)
      CALL UPARLSTAL(IN,IOUT,LINE,NPCHD,MXPC)
      !
      IF(IFREFM.EQ.0) THEN
         READ(LINE,'(I10)',IOSTAT=N) MXACTC
         IF(N.NE.0) THEN
            LLOC=1
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,MXACTC,R,IOUT,IN)
         END IF
         LLOC=11
      ELSE
         LLOC=1
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,MXACTC,R,IOUT,IN)
      END IF
        WRITE(IOUT,3) MXACTC
    3 FORMAT(1X,'MAXIMUM OF ',I6,
     1  ' TIME-VARIANT SPECIFIED-HEAD CELLS AT ONE TIME')
C
C3------READ AUXILIARY VARIABLES AND PRINT OPTION
      ALLOCATE (CHDAUX(20))
      NAUX=0
      IPRCHD=1
   10 CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,LOUT,IN)
      IF(LINE(ISTART:ISTOP).EQ.'AUXILIARY' .OR.
     1        LINE(ISTART:ISTOP).EQ.'AUX') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,LOUT,IN)
         IF(NAUX.LT.20) THEN
            NAUX=NAUX+1
            CHDAUX(NAUX)=LINE(ISTART:ISTOP)
              WRITE(IOUT,12) CHDAUX(NAUX)
   12       FORMAT(1X,'AUXILIARY CHD VARIABLE: ',A)
         END IF
         GO TO 10
      ELSE IF(LINE(ISTART:ISTOP).EQ.'NOPRINT') THEN
           WRITE(IOUT,13)
   13    FORMAT(1X,
     &'LISTS OF TIME-VARIANT SPECIFIED-HEAD CELLS WILL NOT BE PRINTED')
         IPRCHD = 0
         GO TO 10
      END IF
      NCHDVL=5+NAUX
C
C4------ALLOCATE SPACE FOR TIME-VARIANT SPECIFIED-HEAD LIST.
      ICHDPB=MXACTC+1
      MXCHD=MXACTC+MXPC
      ALLOCATE (CHDS(NCHDVL,MXCHD))
C
C1------READ NAMED PARAMETERS.
        WRITE(IOUT,1000) NPCHD
 1000 FORMAT(1X,//1X,I5,' TIME-VARIANT SPECIFIED-HEAD PARAMETERS')
      IF(NPCHD.GT.0) THEN
        NAUX=NCHDVL-5
        LSTSUM=ICHDPB
        DO 120 K=1,NPCHD
          LSTBEG=LSTSUM
          CALL UPARLSTRP(LSTSUM,MXCHD,IN,IOUT,IP,'CHD','CHD',1,
     &                  NUMINST)
          NLST=LSTSUM-LSTBEG
          IF (NUMINST.GT.1) NLST = NLST/NUMINST
C         ASSIGN STARTING INDEX FOR READING INSTANCES
          IF (NUMINST.EQ.0) THEN
            IB=0
          ELSE
            IB=1
          ENDIF
C         READ LIST(S) OF CELLS, PRECEDED BY INSTANCE NAME IF NUMINST>0
          LB=LSTBEG
          DO 110 I=IB,NUMINST
            IF (I.GT.0) THEN
              CALL UINSRP(I,IN,IOUT,IP,IPRCHD)
            ENDIF
            CALL ULSTRD(NLST,CHDS,LB,NCHDVL,MXCHD,0,IN,IOUT,
     &     'CHD NO.   LAYER   ROW   COL   START FACTOR      END FACTOR',
     &      CHDAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,4,5,IPRCHD,CHDGROUP)
            LB=LB+NLST
  110     CONTINUE
  120   CONTINUE
      END IF
C
C3------RETURN.
      CALL SGWF2CHD7PSV(IGRID)
      RETURN
      END
      SUBROUTINE GWF2CHD7RP(IN,IGRID)
C     ******************************************************************
C     READ STRESS PERIOD DATA FOR CHD
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:NCOL,NROW,NLAY,IFREFM,IBOUND
      USE GWFCHDMODULE,ONLY:NCHDS,MXCHD,NCHDVL,IPRCHD,NPCHD,ICHDPB,
     1                      NNPCHD,CHDAUX,CHDS,IOUT,LOUT
      CHARACTER(20),DIMENSION(1):: CHDGROUP
C     ------------------------------------------------------------------
      CHDGROUP='NOGROUP'

      CALL SGWF2CHD7PNT(IGRID)
C
C1------READ ITMP(FLAG TO REUSE DATA AND NUMBER OF PARAMETERS.
      IF(NPCHD.GT.0) THEN
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
C2------CALCULATE NUMBER OF AUXILIARY VALUES
      NAUX=NCHDVL-5
      IOUTU = IOUT
      !IF (IPRCHD.EQ.0) IOUTU = 0
C
C2------TEST ITMP
C2A-----IF ITMP<0 THEN REUSE DATA FROM LAST STRESS PERIOD
      IF(ITMP.LT.0) THEN
           WRITE(IOUT,7)
    7    FORMAT(1X,/1X,'REUSING NON-PARAMETER SPECIFIED-HEAD DATA FROM',
     1     ' LAST STRESS PERIOD')
      ELSE
         NNPCHD=ITMP
      END IF
C
C3------IF THERE ARE NEW NON-PARAMETER CHDS, READ THEM
      MXACTC=ICHDPB-1
      IF(ITMP.GT.0) THEN
         IF(NNPCHD.GT.MXACTC) THEN
              WRITE(LOUT,99) NNPCHD,MXACTC
   99       FORMAT(1X,/1X,'THE NUMBER OF ACTIVE CHD CELLS (',I6,
     1                     ') IS GREATER THAN MXACTC(',I6,')')
            CALL USTOP(' ')
         END IF
         CALL ULSTRD(NNPCHD,CHDS,1,NCHDVL,MXCHD,0,IN,IOUT,
     1    'CHD NO.   LAYER   ROW   COL    START HEAD        END HEAD',
     2     CHDAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,4,5,IPRCHD,CHDGROUP)
      END IF
      NCHDS=NNPCHD
C
Cx------IF THERE ARE ACTIVE CHD PARAMETERS, READ THEM AND SUBSTITUTE
      CALL PRESET('CHD')
      IF(NP.GT.0) THEN
         DO 30 N=1,NP
         CALL UPARLSTSUB(IN,'CHD',IOUTU,'CHD',CHDS,NCHDVL,MXCHD,NCHDVL,
     1             MXACTC,NCHDS,4,5,
     2    'CHD NO.   LAYER   ROW   COL    START HEAD        END HEAD',
     3            CHDAUX,20,NAUX,IPRCHD,CHDGROUP)
   30    CONTINUE
      END IF
C
C4------PRINT # OF SPECIFIED-HEAD CELLS THIS STRESS PERIOD
          WRITE(IOUT,1) NCHDS
    1 FORMAT(1X,//1X,I6,' TIME-VARIANT SPECIFIED-HEAD CELLS')
C
C5------SET IBOUND NEGATIVE AT SPECIFIED-HEAD CELLS.
      DO 250 II=1,NCHDS
      IL=CHDS(1,II)
      IR=CHDS(2,II)
      IC=CHDS(3,II)
      IF(IBOUND(IC,IR,IL).GT.0) IBOUND(IC,IR,IL)=-IBOUND(IC,IR,IL)
!      IF(IBOUND(IC,IR,IL).EQ.0) THEN seb no 
!             WRITE(LOUT,6) IL,IR,IC
!    6    FORMAT(1X,'CELL (',I3,',',I5,',',I5,') IS NO FLOW (IBOUND=0)',/
!     1      1X,'NO-FLOW CELLS CANNOT BE CONVERTED TO SPECIFIED HEAD')
!         CALL USTOP(' ')
!      END IF
  250 CONTINUE
C
C8------RETURN
      RETURN
      END
      SUBROUTINE GWF2CHD7AD(KPER,IGRID)
C     ******************************************************************
C     COMPUTE HEAD FOR TIME STEP AT EACH TIME-VARIANT SPECIFIED HEAD
C     CELL.
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:HNEW,HOLD,PERLEN,IBOUND
      USE GWFBASMODULE,ONLY:PERTIM,HDRY
      USE GWFCHDMODULE,ONLY:NCHDS,CHDS,IOUT
C
      DOUBLE PRECISION DZERO,HB
C     ------------------------------------------------------------------
      CALL SGWF2CHD7PNT(IGRID)
      DZERO=0D0
C
C1------IF NCHDS<=0 THEN THERE ARE NO TIME VARIANT SPECIFIED-HEAD CELLS.
C1------RETURN.
      IF(NCHDS.LE.0) RETURN
C
C6------INITIALIZE HNEW TO 0 AT SPECIFIED-HEAD CELLS.
      DO 50 L=1,NCHDS
      IL=CHDS(1,L)
      IR=CHDS(2,L)
      IC=CHDS(3,L)
      HNEW(IC,IR,IL)=DZERO
   50 CONTINUE
C
C2------COMPUTE PROPORTION OF STRESS PERIOD TO CENTER OF THIS TIME STEP
      IF (PERLEN(KPER).EQ.0.0) THEN
        FRAC=1.0
      ELSE
        FRAC=PERTIM/PERLEN(KPER)
      ENDIF
C
C2------PROCESS EACH ENTRY IN THE SPECIFIED-HEAD CELL LIST (CHDS)
      DO 100 L=1,NCHDS
C
C3------GET COLUMN, ROW AND LAYER OF CELL CONTAINING BOUNDARY
      IL=CHDS(1,L)
      IR=CHDS(2,L)
      IC=CHDS(3,L)
C
      IF (PERLEN(KPER).EQ.0.0 .AND. CHDS(4,L).NE.CHDS(5,L)) THEN
          WRITE(LOUT,200)IL,IR,IC
 200    FORMAT(/,' ***WARNING***  FOR CHD CELL (',I3,',',I5,',',I5,
     &'), START HEAD AND END HEAD DIFFER',/,
     &' FOR A STRESS PERIOD OF ZERO LENGTH --',/,
     &' USING ENDING HEAD AS CONSTANT HEAD',
     &' (GWF2CHD7AD)',/)
      ENDIF
C5------COMPUTE HEAD AT CELL BY LINEAR INTERPOLATION.
      HB=CHDS(4,L)+(CHDS(5,L)-CHDS(4,L))*FRAC
C
C6------UPDATE THE APPROPRIATE HNEW VALUE
      HNEW(IC,IR,IL)=HNEW(IC,IR,IL)+HB
      HOLD(IC,IR,IL)=HNEW(IC,IR,IL)
  100 CONTINUE
C
C7------RETURN
      RETURN
      END
      SUBROUTINE GWF2CHD7DA(IGRID)
C  Deallocate CHD data for a grid
      USE GWFCHDMODULE
C
        DEALLOCATE(GWFCHDDAT(IGRID)%NCHDS)
        DEALLOCATE(GWFCHDDAT(IGRID)%MXCHD)
        DEALLOCATE(GWFCHDDAT(IGRID)%NCHDVL)
        DEALLOCATE(GWFCHDDAT(IGRID)%IPRCHD)
        DEALLOCATE(GWFCHDDAT(IGRID)%NPCHD)
        DEALLOCATE(GWFCHDDAT(IGRID)%ICHDPB)
        DEALLOCATE(GWFCHDDAT(IGRID)%NNPCHD)
        DEALLOCATE(GWFCHDDAT(IGRID)%CHDAUX)
        DEALLOCATE(GWFCHDDAT(IGRID)%CHDS)
        DEALLOCATE(GWFCHDDAT(IGRID)%IOUT   )
        DEALLOCATE(GWFCHDDAT(IGRID)%LOUT   )
C
C NULLIFY LOCAL POINTERS
      IF (IGRID.EQ.1)THEN
        NCHDS=>NULL()
        MXCHD=>NULL()
        NCHDVL=>NULL()
        IPRCHD=>NULL()
        NPCHD=>NULL()
        ICHDPB=>NULL()
        NNPCHD=>NULL()
        CHDAUX=>NULL()
        CHDS=>NULL()
        IOUT   =>NULL()
        LOUT   =>NULL()
      END IF
      RETURN
      END
      SUBROUTINE SGWF2CHD7PNT(IGRID)
C  Set pointers to CHD data for a grid
      USE GWFCHDMODULE
C
        NCHDS=>GWFCHDDAT(IGRID)%NCHDS
        MXCHD=>GWFCHDDAT(IGRID)%MXCHD
        NCHDVL=>GWFCHDDAT(IGRID)%NCHDVL
        IPRCHD=>GWFCHDDAT(IGRID)%IPRCHD
        NPCHD=>GWFCHDDAT(IGRID)%NPCHD
        ICHDPB=>GWFCHDDAT(IGRID)%ICHDPB
        NNPCHD=>GWFCHDDAT(IGRID)%NNPCHD
        CHDAUX=>GWFCHDDAT(IGRID)%CHDAUX
        CHDS=>GWFCHDDAT(IGRID)%CHDS
        IOUT   =>GWFCHDDAT(IGRID)%IOUT
        LOUT   =>GWFCHDDAT(IGRID)%LOUT
C
      RETURN
      END
      SUBROUTINE SGWF2CHD7PSV(IGRID)
C  Save pointers to CHD data for a grid
      USE GWFCHDMODULE
C
        GWFCHDDAT(IGRID)%NCHDS=>NCHDS
        GWFCHDDAT(IGRID)%MXCHD=>MXCHD
        GWFCHDDAT(IGRID)%NCHDVL=>NCHDVL
        GWFCHDDAT(IGRID)%IPRCHD=>IPRCHD
        GWFCHDDAT(IGRID)%NPCHD=>NPCHD
        GWFCHDDAT(IGRID)%ICHDPB=>ICHDPB
        GWFCHDDAT(IGRID)%NNPCHD=>NNPCHD
        GWFCHDDAT(IGRID)%CHDAUX=>CHDAUX
        GWFCHDDAT(IGRID)%CHDS=>CHDS
        GWFCHDDAT(IGRID)%IOUT   =>IOUT
        GWFCHDDAT(IGRID)%LOUT   =>LOUT
C
      RETURN
      END
