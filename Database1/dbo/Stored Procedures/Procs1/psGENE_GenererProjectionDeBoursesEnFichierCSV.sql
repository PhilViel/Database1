/****************************************************************************************************
Code de service		:		psGENE_GenererProjectionDeBoursesEnFichierCSV
Nom du service		:		psGENE_GenererProjectionDeBoursesEnFichierCSV
But					:		Pour rendre disponible le résultat de la sp RP_UN_ScholarshipProjection en fichier CSV
							En date de fin du mois précédent 
							JIRA TI-6924  
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_GenererProjectionDeBoursesEnFichierCSV 

                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2017-02-24					Donald Huppé							Création du Service
						2017-03-01					Donald Huppé							Changer nom du fichier
						2017-08-04					Donald Huppé							Ajout de PmtQty
						2018-08-21					Donald Huppé							jira prod-11573
						2018-09-11					Donald Huppé							jira prod-11573 ajout de MontantSouscrit
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_GenererProjectionDeBoursesEnFichierCSV] 
	--(
	
	--)


AS
BEGIN


	DECLARE @EnDateDu datetime
	DECLARE @vcNomFichier varchar(500)

	-- Fin du mois précédent
	SET	@EnDateDu = DATEADD(dd,-1, DATEADD(mm, DATEDIFF(mm,0,GETDATE()), 0)) 

	SET @vcNomFichier = '\\srvapp06\PlanDeClassification\000_PANIER_DE_CLASSEMENT\000-100_TOUS\' + REPLACE(LEFT(CONVERT(VARCHAR, @EnDateDu, 120), 10),'-','') + '_bd_uniacces.csv'
	
	IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'TBL_TEMP_ScholarshipProjection')
		DROP TABLE TBL_TEMP_ScholarshipProjection

	IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'TBL_TEMP_ScholarshipProjection_2')
		DROP TABLE TBL_TEMP_ScholarshipProjection_2

	CREATE TABLE TBL_TEMP_ScholarshipProjection (
		UnitID INT,	
		PlanDesc VARCHAR(75),
		ConventionNo VARCHAR(75),
		InForceDate DATETIME,
		BirthDate DATETIME,
		UnitQty FLOAT,
		CotisationFee MONEY,
		PmtByYearID INT,
		PmtQty INT,
		SubscInsurRate MONEY,
		fTotCotisation MONEY,
		fTotFee MONEY,
		dtEstimateRI DATETIME,
		fCESG MONEY,
		bCESGRequested INT,
		dtLastDeposit DATETIME,
		YearQualif INT,
		fACESG MONEY,
		bACESGRequested INT,
		fCLB MONEY,
		bCLBRequested INT,
		StateName VARCHAR(75),
		fIQEE MONEY,
		fIQEEMaj MONEY,
		bSouscripteur_Desire_IQEE INT

		,Rend_Cotisation MONEY,
		Rend_SCEE MONEY,
		Rend_SCEEmajoree MONEY,
		Rend_BEC MONEY,
		Rend_IQEE MONEY,
		Rend_IQEEmajoree MONEY,
		RatioDemandePAE FLOAT,
		MontantSouscrit MONEY

		)

	INSERT INTO TBL_TEMP_ScholarshipProjection
	EXEC RP_UN_ScholarshipProjection @EnDateDu


	SELECT --top 20 
		UnitID ,	
		PlanDesc,
		ConventionNo,
		InForceDate,
		BirthDate,
		UnitQty = replace(cast(round(UnitQty,3) as VARCHAR(10)),'.',',') ,
		CotisationFee = replace(cast(round(CotisationFee,2) as VARCHAR(10)),'.',',') ,
		PmtByYearID ,
		PmtQty,
		SubscInsurRate = replace(cast(round(SubscInsurRate,2) as VARCHAR(10)),'.',',') ,
		fTotCotisation = replace(cast(round(fTotCotisation,2) as VARCHAR(10)),'.',',') ,
		fTotFee = replace(cast(round(fTotFee,2) as VARCHAR(10)),'.',',') ,
		dtEstimateRI ,
		fCESG = replace(cast(round(fCESG,2) as VARCHAR(10)),'.',',') ,
		bCESGRequested ,
		dtLastDeposit ,
		YearQualif ,
		fACESG = replace(cast(round(fACESG,2) as VARCHAR(10)),'.',',') ,
		bACESGRequested ,
		fCLB = replace(cast(round(fCLB,2) as VARCHAR(10)),'.',',') ,
		bCLBRequested ,
		StateName,
		fIQEE = replace(cast(round(fIQEE,2) as VARCHAR(10)),'.',',') ,
		fIQEEMaj = replace(cast(round(fIQEEMaj,2) as VARCHAR(10)),'.',',') ,
		bSouscripteur_Desire_IQEE, 

		Rend_Cotisation = replace(cast(round(Rend_Cotisation,2) as VARCHAR(10)),'.',','),
		Rend_SCEE = replace(cast(round(Rend_SCEE,2) as VARCHAR(10)),'.',','),
		Rend_SCEEmajoree = replace(cast(round(Rend_SCEEmajoree,2) as VARCHAR(10)),'.',','),
		Rend_BEC = replace(cast(round(Rend_BEC,2) as VARCHAR(10)),'.',','),
		Rend_IQEE = replace(cast(round(Rend_IQEE,2) as VARCHAR(10)),'.',','),
		Rend_IQEEmajoree = replace(cast(round(Rend_IQEEmajoree,2) as VARCHAR(10)),'.',','),
		RatioDemandePAE = replace(cast(round(RatioDemandePAE,4) as VARCHAR(10)),'.',','),
		MontantSouscrit =  replace(cast(round(MontantSouscrit,2) as VARCHAR(10)),'.',',')

	INTO TBL_TEMP_ScholarshipProjection_2 
	FROM TBL_TEMP_ScholarshipProjection 
	



	EXEC('exec master..xp_cmdshell ''del '+@vcNomFichier+'''')

	EXEC SP_ExportTableToExcelWithColumns 'UnivBase', 'TBL_TEMP_ScholarshipProjection_2', @vcNomFichier, 'RAW', 1


	IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'TBL_TEMP_ScholarshipProjection')
		DROP TABLE TBL_TEMP_ScholarshipProjection

	IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'TBL_TEMP_ScholarshipProjection_2')
		DROP TABLE TBL_TEMP_ScholarshipProjection_2


END