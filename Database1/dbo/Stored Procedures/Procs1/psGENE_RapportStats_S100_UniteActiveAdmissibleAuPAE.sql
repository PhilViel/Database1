
/****************************************************************************************************
Code de service		:		psGENE_RapportStats_S100_UniteActiveAdmissibleAuPAE
Nom du service		:		psGENE_RapportStats_S100_UniteActiveAdmissibleAuPAE
But					:		Pour le rapport de statistiques : Unités actives admissibles au PAE
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@dtStartDate				Début de la période
						@dtEndDate					Fin de la période
						@vcRegroupement				Type de regroupement : CONV, COHORTE

Exemple d'appel:
						 exec psGENE_RapportStats_S100_UniteActiveAdmissibleAuPAE '2018-01-01', '2018-09-13', 'CONV' , '000-100'
						 exec psGENE_RapportStats_S100_UniteActiveAdmissibleAuPAE '2018-01-01', '2018-06-11', 'CONV' , '000-100'
						 exec psGENE_RapportStats_S100_UniteActiveAdmissibleAuPAE '2018-01-01', '2018-06-19', 'CONV' , '000-100'
						 exec psGENE_RapportStats_S100_UniteActiveAdmissibleAuPAE '2018-01-01', '2018-06-19', 'COHORTE' , '000-100'
						 exec psGENE_RapportStats_S100_UniteActiveAdmissibleAuPAE '2018-01-01', '2018-04-30', 'COHORTE' , '107-200'
                
						DROP PROC psGENE_RapportStats_S100_UniteActiveAdmissibleAuPAE_test

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2018-05-08					Donald Huppé							Création du Service
						2018-05-14					Donald Huppé							Ratio : Nouvelle condition si solde unité à la fin = 0
						2018-05-16					Donald Huppé							nouveau dossier 107-200
						2018-05-28					Donald Huppé							Prendre les unités avec 1er <= Date deDebut
						2018-06-20					Donald Huppé							Correction du calcul des unités au début et fin
						2018-09-13					Donald Huppé							JIRA PROD-11777 : ajout de NiveauEtude
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStats_S100_UniteActiveAdmissibleAuPAE] (
	@dtStartDate DATETIME,
	@dtEndDate DATETIME,
	@vcRegroupement VARCHAR(30) = 'CONV',
	@Dossier VARCHAR(255) = '107-200'
	)


AS
BEGIN

	SET ARITHABORT ON

	DECLARE 
		@vcNomFichier VARCHAR(500)
		,@dtDateGeneration DATETIME
		,@DossierFinal varchar(500)

	SET @DossierFinal =
			CASE 
			WHEN @Dossier = '000-100' THEN '\\srvapp06\PlanDeClassification\000_PANIER_DE_CLASSEMENT\000-100_TOUS\' 
			--WHEN @Dossier = '201-127' THEN '\\srvapp06\PlanDeClassification\2_ADMINISTRATION_GENERALE\201_ORGANISATION_ADMIN\201-100_PLANIF_ET_COORD\201-120_STATISTIQUES\201-127_FINANCES_ADMIN\2018\'
			WHEN @Dossier = '107-200' THEN '\\srvapp06\PlanDeClassification\1_GOUVERNANCE_ET_AFFAIRES_CORPO\107_BUREAU_PROJET\107-200_PROJETS_ACTIFS\PR2016-33_Outil_de_statistiques\8_UNITES_ADMIS_RECLAM\'
			ELSE ''
			END

	SET	@dtDateGeneration = GETDATE()

	SET @vcNomFichier = 
				@DossierFinal +

				REPLACE(REPLACE(	REPLACE(LEFT(CONVERT(VARCHAR, @dtDateGeneration, 120), 25),'-',''),' ','_'),':','') + 
				'_UniteActiveAdmissibleAuPAE_' +
				REPLACE(LEFT(CONVERT(VARCHAR, @dtStartDate, 120), 10),'-','') + '_au_' +
				REPLACE(LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10),'-','') + 
				'.CSV'

	--SELECT @vcNomFichier
	--RETURN
	

	IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'TBL_TEMP_UniteActiveAdmissibleAuPAE')
		DROP TABLE TBL_TEMP_UniteActiveAdmissibleAuPAE


	DECLARE 
		--@dtStartDate Datetime = '2018-01-01',
		--@dtEndDate Datetime = '2018-04-30',
		@dtDateFinRegimeAconsiderer DATETIME

	SET	@dtDateFinRegimeAconsiderer = DATEADD(
												YEAR
												,CASE WHEN MONTH(@dtStartDate) = 12 AND DAY(@dtStartDate) =31 THEN 0 ELSE -1 END --SON EST LE LE 31 DÉC ALORS C'EST CETTE DATE, SINON, C'EST 31 DÉC PRÉCÉDENT
												,Str(Year(@dtStartDate), 4, 0) + '-12-31'  
											)
	--SELECT @dtDateFinRegimeAconsiderer

	CREATE TABLE #FinRegime (
		ConventionID INT
		,DateFinRegime DATETIME
		)


	IF @dtDateFinRegimeAconsiderer >= '2018-12-31' -- LES FINS DE RÉGIME AVANT CETTE DATE SONT DÉJÀ FERMÉS

		INSERT INTO #FinRegime
		SELECT *
		FROM (

			SELECT 
				c.ConventionID
				,DateFinRegime = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'R', NULL)
		
			FROM Un_Convention C
			JOIN (
				select 
					Cs.conventionid ,
					ccs.startdate,
					cs.ConventionStateID
				from 
					un_conventionconventionstate cs
					join (
						select 
						conventionid,
						startdate = max(startDate)
						from un_conventionconventionstate
						where startDate < DATEADD(d,1 ,@dtStartDate)
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							and cs.ConventionStateID in ('REE','TRA')
				) css on C.conventionid = css.conventionid

			)v
		WHERE DateFinRegime <= @dtDateFinRegimeAconsiderer

	--SELECT * FROM #FinRegime

	--RETURN


	IF @vcRegroupement = 'CONV'
	BEGIN
		SELECT --TOP 1000
			 Regime = RR.vcDescription
			,C.ConventionID
			,C.ConventionNo
			--,ConventionStateID
			,C.BeneficiaryID
			,C.YearQualif
			,NbUnitesDebut =		REPLACE(CAST(ROUND(1.0*
										Udebut.UnitQtyDebut 
									,3) as VARCHAR(10)),'.',',')

			,NbUnitesNonPayeesDebut =	REPLACE(CAST(ROUND(1.0*
											Udebut.UnitQtyDebut - ISNULL(NbUnitesPayeesAvantPeriode ,0)
										,3) as VARCHAR(10)),'.',',')

			,NbUnitesNonPayeesFin =		REPLACE(CAST(ROUND(1.0*
											UFin.UnitQtyFin - ISNULL(NbUnitesPayeesAvantPeriode ,0) - ISNULL(NbUnitesPaePayeesPeriode ,0)
										,3) as VARCHAR(10)),'.',',')

			,NbUnitesPaePayeesPeriode = REPLACE(CAST(ROUND(1.0*
											ISNULL(NbUnitesPaePayeesPeriode ,0)
										,3) as VARCHAR(10)),'.',',')

			,NiveauEtude
			,RatioPayeesPeriode =	

								--REPLACE(
									REPLACE(CAST(ROUND(	1.0 *	
										CASE WHEN UFin.UnitQtyFin > 0 THEN

												CASE WHEN ( Udebut.UnitQtyDebut - ISNULL(NbUnitesPayeesAvantPeriode ,0) ) <> 0 THEN
													ISNULL(NbUnitesPaePayeesPeriode ,0) 
													/ 
													( Udebut.UnitQtyDebut - ISNULL(NbUnitesPayeesAvantPeriode ,0) )
												ELSE 0
												END
										ELSE -1
										END
									,6) as VARCHAR(10)),'.',',')
									--	,'-1','N/A')

			,RatioPayeesTotal =		
								--REPLACE(
									REPLACE(CAST(ROUND(	
										CASE WHEN UFin.UnitQtyFin > 0 THEN

												1.0 -	
												CASE WHEN Udebut.UnitQtyDebut <> 0 THEN
													(UFin.UnitQtyFin - ISNULL(NbUnitesPayeesAvantPeriode ,0) - ISNULL(NbUnitesPaePayeesPeriode ,0)  )
													/
													Udebut.UnitQtyDebut 
												ELSE 0
												END

										ELSE -1
										END
									,6) as VARCHAR(10)),'.',',')
									--	,'-1','N/A')


			,NbUnitesFin =	REPLACE(CAST(ROUND(1.0*
								UFin.UnitQtyFin 
							,3) as VARCHAR(10)),'.',',')

			,cssDebut.ConventionStateIDDebut
			,cssFin.ConventionStateIDFIN
			,NbUnitesResilieesPeriode = REPLACE(CAST(ROUND(1.0*
										Udebut.UnitQtyDebut 
										- 
										UFin.UnitQtyFin 
									,3) as VARCHAR(10)),'.',',')



			--,DateFinRegime = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'R', NULL)
			--,NbUnitesPayeesAvantPeriode = ISNULL(NbUnitesPayeesAvantPeriode ,0)
			--,NbUnitesPaePayeesPeriode = ISNULL(NbUnitesPaePayeesPeriode ,0)
			--,NbUnitesPayeesApresPeriode = ISNULL(NbUnitesPayeesApresPeriode ,0)
		
		INTO TBL_TEMP_UniteActiveAdmissibleAuPAE
		FROM 
			Un_Convention C
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
			JOIN (
				select 
					Cs.conventionid ,
					ccs.startdate,
					ConventionStateIDDebut = cs.ConventionStateID
				from 
					un_conventionconventionstate cs
					join (
						select 
						conventionid,
						startdate = max(startDate)
						from un_conventionconventionstate
						where startDate < DATEADD(d,1 ,@dtStartDate)
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							and cs.ConventionStateID in ('REE','TRA')
				) cssDebut on cssDebut.conventionid = c.conventionid

			JOIN (
				select 
					Cs.conventionid ,
					ccs.startdate,
					ConventionStateIDFIN = cs.ConventionStateID
				from 
					un_conventionconventionstate cs
					join (
						select 
						conventionid,
						startdate = max(startDate)
						from un_conventionconventionstate
						where startDate < DATEADD(d,1 ,@dtEndDate)
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							--and cs.ConventionStateID in ('REE','TRA')
				) cssFin on cssFin.conventionid = c.conventionid

			JOIN (
				SELECT 
					U2.ConventionID
					,UnitQtyDebut = SUM(U2.UnitQty + ISNULL(URD.QTERES,0) )
				FROM Un_Unit U2
				LEFT JOIN (SELECT UnitID, QTERES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtStartDate GROUP BY UnitID )URD ON URD.UnitID = U2.UnitID
				WHERE ISNULL(U2.dtFirstDeposit,'9999-12-31') <= @dtStartDate
				GROUP BY U2.ConventionID
				)Udebut ON Udebut.ConventionID = C.ConventionID

			JOIN (
				SELECT 
					U2.ConventionID
					,UnitQtyFin = SUM(U2.UnitQty + ISNULL(URF.QTERES,0) )
				FROM Un_Unit U2
				LEFT JOIN (SELECT UnitID, QTERES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtEndDate GROUP BY UnitID )URF ON URF.UnitID = U2.UnitID
				WHERE ISNULL(U2.dtFirstDeposit,'9999-12-31') <= @dtEndDate
				GROUP BY U2.ConventionID
				)UFin ON UFin.ConventionID = C.ConventionID

			LEFT JOIN (
				SELECT 
					S.ConventionID
					,NbUnitesPayeesAvantPeriode =	SUM(CASE WHEN DatePAE < @dtStartDate						THEN S.mQuantite_UniteDemande ELSE 0 END) 
					,NbUnitesPaePayeesPeriode =		SUM(CASE WHEN DatePAE BETWEEN @dtStartDate AND @dtEndDate	THEN S.mQuantite_UniteDemande ELSE 0 END) 
					,NbUnitesPayeesApresPeriode =	SUM(CASE WHEN DatePAE > @dtEndDate							THEN S.mQuantite_UniteDemande ELSE 0 END) 

				FROM 
					Un_Scholarship S
					JOIN (
						SELECT S1.ScholarshipID, DatePAE = MAX(O1.OperDate)
						FROM Un_Scholarship S1
						JOIN Un_ScholarshipPmt SP1 ON SP1.ScholarshipID = S1.ScholarshipID
						JOIN UN_OPER O1 ON O1.OperID = SP1.OperID
						LEFT JOIN Un_OperCancelation OC11 ON OC11.OperSourceID = O1.OperID
						LEFT JOIN Un_OperCancelation OC21 ON OC21.OperID = O1.OperID
						WHERE
							OC11.OperSourceID IS NULL
							AND OC21.OperID IS NULL
						GROUP BY S1.ScholarshipID
						)MO ON MO.ScholarshipID = S.ScholarshipID

				WHERE 1=1
					AND S.ScholarshipStatusID IN ('24Y','25Y','DEA','PAD','REN')
				GROUP BY S.ConventionID

				) PAE ON PAE.ConventionID = C.ConventionID

			LEFT JOIN (
				SELECT S1.ConventionID
						,NiveauEtude = MAX( -- JUSTE POUR ÊTRE CERTAIN D'AVOIR JUSTE UNE LIGNE PAR CONVENTION. AU CAS OU 2 PAE DIFFÉRENT LA MÊME JOURNÉE
											 CASE 
											WHEN p.ProgramDesc LIKE 'DEP-%' THEN 'DEP'
											WHEN p.ProgramDesc LIKE 'AEC-%' THEN 'AEC'
											when p.ProgramDesc LIKE '%préuniversitaire%' THEN 'DEC-GEN'
											when cl.CollegeTypeID IN ( '02','03','04') AND sp1.ProgramLength > 2 THEN 'DEC-TECH'
											when cl.CollegeTypeID IN ('02','03','04') AND sp1.ProgramLength <= 2 THEN 'AEC'
											when cl.CollegeTypeID = '01' THEN 'BAC'
											when p.ProgramDesc LIKE '(Programme inconnu) NE PAS CHOISIR CE TYPE' AND sp1.ProgramLength = 3  then 'DEC-TECH'
											ELSE 'ND'
											END
											)
				FROM 
					Un_Scholarship S1
					JOIN Un_ScholarshipPmt SP1 ON SP1.ScholarshipID = S1.ScholarshipID
					JOIN Un_Oper O1 ON O1.OperID = SP1.OperID
					JOIN (
						SELECT 
							S.ConventionID, MAXDatePAE = MAX(MO.DatePAE) -- DERNIERE DATE DE PAE DANS LA PÉRIODE
						FROM 
							Un_Scholarship S
							JOIN (
								SELECT S1.ScholarshipID, DatePAE = MAX(O1.OperDate)
								FROM Un_Scholarship S1
								JOIN Un_ScholarshipPmt SP1 ON SP1.ScholarshipID = S1.ScholarshipID
								JOIN UN_OPER O1 ON O1.OperID = SP1.OperID
								LEFT JOIN Un_OperCancelation OC11 ON OC11.OperSourceID = O1.OperID
								LEFT JOIN Un_OperCancelation OC21 ON OC21.OperID = O1.OperID
								WHERE
									OC11.OperSourceID IS NULL
									AND OC21.OperID IS NULL
								--HAVING MAX(O1.OperDate) BETWEEN '2018-01-01' AND '2018-09-13'
								GROUP BY S1.ScholarshipID
								)MO ON MO.ScholarshipID = S.ScholarshipID
						WHERE MO.DatePAE BETWEEN @dtStartDate AND @dtEndDate
						AND S.ScholarshipStatusID IN ('24Y','25Y','DEA','PAD','REN')
						GROUP BY S.ConventionID
						)DP	 ON DP.ConventionID = S1.ConventionID AND DP.MAXDatePAE = O1.OperDate -- DERNIERE DATE DE PAE DANS LA PÉRIODE
					LEFT JOIN un_program p on sp1.ProgramID = p.ProgramId
					LEFT JOIN un_college cl on sp1.CollegeID = cl.CollegeID
					LEFT JOIN mo_company co on co.companyid = cl.CollegeID
				GROUP BY S1.ConventionID
			)NIV ON NIV.ConventionID = C.ConventionID

			LEFT JOIN #FinRegime FR ON FR.ConventionID = C.ConventionID
			WHERE  
				Udebut.UnitQtyDebut > 0
				AND FR.ConventionID IS NULL
			ORDER BY RR.vcDescription, c.YearQualif, c.ConventionID DESC
	END

	IF @vcRegroupement = 'COHORTE'
	BEGIN

		SELECT --TOP 1000
			 Regime = RR.vcDescription
			,C.YearQualif
			,NbUnitesDebut =		REPLACE(CAST(ROUND(1.0*
										SUM(Udebut.UnitQtyDebut)
									,3) as VARCHAR(30)),'.',',')

			,NbUnitesNonPayeesDebut =	REPLACE(CAST(ROUND(1.0*
											SUM((Udebut.UnitQtyDebut) - ISNULL(NbUnitesPayeesAvantPeriode ,0))
										,3) as VARCHAR(30)),'.',',')

			,NbUnitesNonPayeesFin =		REPLACE(CAST(ROUND(1.0*
											SUM((UFin.UnitQtyFin) - ISNULL(NbUnitesPayeesAvantPeriode ,0) - ISNULL(NbUnitesPaePayeesPeriode ,0))
										,3) as VARCHAR(30)),'.',',')

			,NbUnitesPaePayeesPeriode = REPLACE(CAST(ROUND(1.0*
											SUM(ISNULL(NbUnitesPaePayeesPeriode ,0))
										,3) as VARCHAR(30)),'.',',')

			,RatioPayeesPeriode =	REPLACE(CAST(ROUND(	1.0 *	
										CASE WHEN  SUM( (( Udebut.UnitQtyDebut) - ISNULL(NbUnitesPayeesAvantPeriode ,0) ) ) <> 0 THEN
											SUM( ISNULL(NbUnitesPaePayeesPeriode ,0) )
											/ 
											SUM( ( Udebut.UnitQtyDebut - ISNULL(NbUnitesPayeesAvantPeriode ,0) ) )
										ELSE 0
										END
									,6) as VARCHAR(30)),'.',',')
			,RatioPayeesTotal =		REPLACE(CAST(ROUND(	
										1.0 -	
										CASE WHEN SUM( Udebut.UnitQtyDebut) <> 0 THEN
											SUM( ( (UFin.UnitQtyFin) - ISNULL(NbUnitesPayeesAvantPeriode ,0) - ISNULL(NbUnitesPaePayeesPeriode ,0)  ) )
											/
											SUM( ( Udebut.UnitQtyDebut ) )
										ELSE 0
										END
									,6) as VARCHAR(30)),'.',',')

			,NbUnitesFin =	REPLACE(CAST(ROUND(1.0*
								SUM( UFin.UnitQtyFin )
							,3) as VARCHAR(30)),'.',',')


			,NbUnitesResilieesPeriode = REPLACE(CAST(ROUND(1.0*
										SUM( Udebut.UnitQtyDebut )
										- 
										SUM( UFin.UnitQtyFin )
									,3) as VARCHAR(10)),'.',',')

			--,DateFinRegime = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'R', NULL)
			--,NbUnitesPayeesAvantPeriode = ISNULL(NbUnitesPayeesAvantPeriode ,0)
			--,NbUnitesPaePayeesPeriode = ISNULL(NbUnitesPaePayeesPeriode ,0)
			--,NbUnitesPayeesApresPeriode = ISNULL(NbUnitesPayeesApresPeriode ,0)
		
		INTO TBL_TEMP_UniteActiveAdmissibleAuPAE
		FROM 
			Un_Convention C
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
			JOIN (
				select 
					Cs.conventionid ,
					ccs.startdate,
					cs.ConventionStateID
				from 
					un_conventionconventionstate cs
					join (
						select 
						conventionid,
						startdate = max(startDate)
						from un_conventionconventionstate
						where startDate < DATEADD(d,1 ,@dtStartDate)
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							and cs.ConventionStateID in ('REE','TRA')
				) css on C.conventionid = css.conventionid

			JOIN (
				SELECT 
					U2.ConventionID
					,UnitQtyDebut = SUM(U2.UnitQty + ISNULL(URD.QTERES,0) )
				FROM Un_Unit U2
				LEFT JOIN (SELECT UnitID, QTERES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtStartDate GROUP BY UnitID )URD ON URD.UnitID = U2.UnitID
				WHERE ISNULL(U2.dtFirstDeposit,'9999-12-31') <= @dtStartDate
				GROUP BY U2.ConventionID
				)Udebut ON Udebut.ConventionID = C.ConventionID

			JOIN (
				SELECT 
					U2.ConventionID
					,UnitQtyFin = SUM(U2.UnitQty + ISNULL(URF.QTERES,0) )
				FROM Un_Unit U2
				LEFT JOIN (SELECT UnitID, QTERES = SUM(UnitQty) FROM Un_UnitReduction WHERE ReductionDate > @dtEndDate GROUP BY UnitID )URF ON URF.UnitID = U2.UnitID
				WHERE ISNULL(U2.dtFirstDeposit,'9999-12-31') <= @dtEndDate
				GROUP BY U2.ConventionID
				)UFin ON UFin.ConventionID = C.ConventionID

			LEFT JOIN (
				SELECT 
					S.ConventionID
					,NbUnitesPayeesAvantPeriode =	SUM(CASE WHEN DatePAE < @dtStartDate						THEN S.mQuantite_UniteDemande ELSE 0 END) 
					,NbUnitesPaePayeesPeriode =		SUM(CASE WHEN DatePAE BETWEEN @dtStartDate AND @dtEndDate	THEN S.mQuantite_UniteDemande ELSE 0 END) 
					,NbUnitesPayeesApresPeriode =	SUM(CASE WHEN DatePAE > @dtEndDate							THEN S.mQuantite_UniteDemande ELSE 0 END) 

				FROM 
					Un_Scholarship S
					JOIN (
						SELECT S1.ScholarshipID, DatePAE = MAX(O1.OperDate)
						FROM Un_Scholarship S1
						JOIN Un_ScholarshipPmt SP1 ON SP1.ScholarshipID = S1.ScholarshipID
						JOIN UN_OPER O1 ON O1.OperID = SP1.OperID
						LEFT JOIN Un_OperCancelation OC11 ON OC11.OperSourceID = O1.OperID
						LEFT JOIN Un_OperCancelation OC21 ON OC21.OperID = O1.OperID
						WHERE
							OC11.OperSourceID IS NULL
							AND OC21.OperID IS NULL
						GROUP BY S1.ScholarshipID
						)MO ON MO.ScholarshipID = S.ScholarshipID

				WHERE 1=1
					AND S.ScholarshipStatusID IN ('24Y','25Y','DEA','PAD','REN')
				GROUP BY S.ConventionID
				) PAE ON PAE.ConventionID = C.ConventionID

			LEFT JOIN #FinRegime FR ON FR.ConventionID = C.ConventionID
			WHERE  
				Udebut.UnitQtyDebut > 0
				AND FR.ConventionID IS NULL
			GROUP BY
				RR.vcDescription
				,C.YearQualif
			ORDER BY
				RR.vcDescription
				,C.YearQualif

	END

	


	CREATE TABLE #tOutPut (f1 varchar(2000))

	INSERT #tOutPut
	EXEC('exec master..xp_cmdshell ''del '+@vcNomFichier+'''')

	INSERT #tOutPut
	EXEC SP_ExportTableToExcelWithColumns 'UnivBase', 'TBL_TEMP_UniteActiveAdmissibleAuPAE', @vcNomFichier, 'RAW', 1

	IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'TBL_TEMP_UniteActiveAdmissibleAuPAE')
		DROP TABLE TBL_TEMP_UniteActiveAdmissibleAuPAE	

	--SELECT * from #tOutPut

	SELECT 
		Du = cast(@dtStartDate as date),
		Au = cast(@dtEndDate as date),
		NomFichier = @vcNomFichier


SET ARITHABORT OFF

END
			
