/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	psOPER_RapportSommaireFiducieRegimeIndividuel
Description         :	Rapprot des solde d'épargne, subvention et rendement des convention individuelles
Valeurs de retours  :	Dataset de données

Note                :	
					2013-01-23	Donald Huppé	Création :  GLPI 8974

exec psConv_RapportConventionTRIAvecRendNegatif '2013-08-01'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psConv_RapportConventionTRIAvecRendNegatif] (
	@dtDateTo DATETIME -- Date de fin de l'intervalle des opérations
	)
AS
BEGIN

	DECLARE @vcRIO_TRANSFERT_TRANSAC_CONVENTION VARCHAR(200)
			
	SET @vcRIO_TRANSFERT_TRANSAC_CONVENTION = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('RIO-TRANSFERT-TRANSAC-CONVENTION')

--Épargne, Rend sur épargne, Subventions (SCEE, IQEE, BEC), Rend sur les subventions, et les frais (moins les montants de bourses ou de RI versés s'il y a lieu). 

	SELECT DISTINCT

		C.conventionno,

		--NomBeneficiaire = hb.FirstName + ' ' + hb.LastName,
		--AdresseBeneficiaire = a.Address,
		--VilleBeneficiaire = a.City,
		--CodePostalBeneficiaire = a.ZipCode,
		--PaysBeneficiaire = a.CountryID,
		
		SCEE = ISNULL(SCEE,0),
		RendSCEE = ISNULL(INS,0),
		RendSCEE_TIN = ISNULL(IST,0),
		SCEEPlus = ISNULL(SCEEPlus,0),
		RendSCEEPlus = ISNULL(ISPlus,0), 
		BEC = ISNULL(BEC,0),
		RendBEC = ISNULL(IBC,0),
		IQEE = ISNULL(IQEEBase,0),
		RendIQEE = ISNULL(ICQ,0),
		RendIQEE_TIN = ISNULL(III,0),
		RendSurInteretRecuRQ = ISNULL(IIQ,0),
		IQEEPlus = ISNULL(IQEEMajore,0),
		RendIQEEPlus = ISNULL(IMQ,0),
		RendMontantsouscrit = ISNULL(RendMontantsouscrit,0),
		RendTIN = ISNULL(RendTIN,0)
	
	--into t2	
		
	FROM dbo.Un_Convention c
	join tblOPER_OperationsRIO rio ON c.ConventionID = rio.iID_Convention_Source and rio.bRIO_Annulee = 0 and rio.bRIO_QuiAnnule = 0 and rio.OperTypeID = 'TRI'
	/*
	join (
		SELECT DISTINCT  R.iID_Convention_Source
		FROM tblOPER_OperationsRIO R
		
		WHERE R.bRIO_Annulee = 0
		  AND R.bRIO_QuiAnnule = 0
		  AND R.dtDate_Enregistrement = (SELECT MIN(R2.dtDate_Enregistrement)
										 FROM tblOPER_OperationsRIO R2
										 WHERE R2.iID_Convention_Source = R.iID_Convention_Source AND
											   R2.bRIO_Annulee = 0 AND
											   R2.bRIO_QuiAnnule = 0)
		  -- qui ont un solde transférable par le RIO...
		  AND 0 < (SELECT ISNULL(SUM(OC.ConventionOperAmount),0)
					FROM dbo.Un_ConventionOper OC
					WHERE OC.ConventionID = R.iID_Convention_Source
					  AND (CHARINDEX(OC.ConventionOperTypeID,@vcRIO_TRANSFERT_TRANSAC_CONVENTION) > 0))
		  -- qui ont un compte en perte
		  AND /*NOT*/ EXISTS (SELECT CO.ConventionOperTypeID,SUM(CO.ConventionOperAmount)
						  FROM Un_ConventionOper CO
						  WHERE CO.ConventionID = R.iID_Convention_Source
							AND (CHARINDEX(CO.ConventionOperTypeID,@vcRIO_TRANSFERT_TRANSAC_CONVENTION) > 0)
						  GROUP BY CO.ConventionOperTypeID
						  HAVING SUM(CO.ConventionOperAmount) < 0)
			and R.OperTypeID = 'TRI'
		) rio ON c.ConventionID = rio.iID_Convention_Source
	*/
	left JOIN (
		select 
			c1.ConventionID,			

			IQEEBase = sum(case when co.conventionopertypeid = 'CBQ' then ConventionOperAmount else 0 end ),
			IQEEMajore = sum(case when co.conventionopertypeid = 'MMQ' then ConventionOperAmount else 0 end ),
			
			RendMontantsouscrit = sum(case when co.conventionopertypeid = 'INM' then ConventionOperAmount else 0 end ),
			RendTIN = sum(case when co.conventionopertypeid = 'ITR' then ConventionOperAmount else 0 end ),
			IBC = sum(case when co.conventionopertypeid = 'IBC' then ConventionOperAmount else 0 end ),
			ICQ = sum(case when co.conventionopertypeid = 'ICQ' then ConventionOperAmount else 0 end ),
			III = sum(case when co.conventionopertypeid = 'III' then ConventionOperAmount else 0 end ),
			IIQ = sum(case when co.conventionopertypeid = 'IIQ' then ConventionOperAmount else 0 end ),
			IMQ = sum(case when co.conventionopertypeid = 'IMQ' then ConventionOperAmount else 0 end ),
			INS = sum(case when co.conventionopertypeid = 'INS' then ConventionOperAmount else 0 end ),
			ISPlus = sum(case when co.conventionopertypeid = 'IS+' then ConventionOperAmount else 0 end ),
			IST = sum(case when co.conventionopertypeid = 'IST' then ConventionOperAmount else 0 end )
		from 
			un_conventionoper co
			join Un_Oper o ON co.OperID = o.OperID
			JOIN dbo.Un_Convention c1 on co.conventionid = c1.conventionid
			--join tblOPER_OperationsRIO rio1 ON c1.ConventionID = rio1.iID_Convention_Source and rio1.bRIO_Annulee = 0 and rio1.bRIO_QuiAnnule = 0 and rio1.OperTypeID = 'TRI'
			JOIN Un_Plan P ON c1.PlanID = P.PlanID
		where 1=1
		--and p.PlanTypeID = 'IND'
		and o.operdate <= @dtDateTo
		and co.conventionopertypeid in('INS','IS+','CBQ','MMQ' ,'IBC','ICQ','IIQ','IMQ','IST','INM','ITR','III')
		--,IBC,INS,IS+,IST,INM,ITR,CBQ,MMQ,MIM,IQI,ICQ,IMQ,IIQ,III,
		--select * from un_conventionopertype
		GROUP BY c1.ConventionID
		) v on c.ConventionID = v.ConventionID
	left join (
		select 
			ce.conventionid,
			SCEE = sum(fcesg),
			SCEEPlus = sum(facesg),
			BEC = sum(fCLB)
		from un_cesp ce
		JOIN dbo.Un_Convention c2 on ce.conventionid = c2.conventionid
		--join tblOPER_OperationsRIO rio2 ON c2.ConventionID = rio2.iID_Convention_Source and rio2.bRIO_Annulee = 0 and rio2.bRIO_QuiAnnule = 0 and rio2.OperTypeID = 'TRI'
		JOIN Un_Plan P ON c2.PlanID = P.PlanID
		join un_oper op on ce.operid = op.operid
		where op.operdate <= @dtDateTo
		--and p.PlanTypeID = 'IND'
		group by ce.conventionid
		)scee on c.conventionid = scee.conventionid

	WHERE 1=1 
		--and c.ConventionNo = 'X-20100813006'
	
		and (
		ISNULL(SCEE,0) > 0 or
		ISNULL(SCEEPlus,0) > 0 or
		ISNULL(BEC,0) > 0 or
		ISNULL(IQEEBase,0) > 0 or
		ISNULL(IQEEMajore,0)  > 0
		)
		
		and (
			ISNULL(INS,0) < 0
			or ISNULL(ISPlus,0) < 0
			or ISNULL(IBC,0) < 0
			or ISNULL(ICQ,0) < 0
			or ISNULL(IIQ,0) < 0
			or ISNULL(IMQ,0) < 0
			or ISNULL(RendMontantsouscrit,0) < 0
			OR ISNULL(RendTIN,0) < 0
			or ISNULL(IST,0) < 0
			or ISNULL(III,0) < 0
			)
		
END

/*

SELECT [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('RIO-TRANSFERT-TRANSAC-CONVENTION')

	DECLARE @vcRIO_TRANSFERT_TRANSAC_CONVENTION VARCHAR(200)
			
	SET @vcRIO_TRANSFERT_TRANSAC_CONVENTION = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('RIO-TRANSFERT-TRANSAC-CONVENTION')

		select *
		from (
		SELECT DISTINCT  R.iID_Convention_Source
							
		FROM tblOPER_OperationsRIO R
		
		WHERE R.bRIO_Annulee = 0
		  AND R.bRIO_QuiAnnule = 0
		  AND R.dtDate_Enregistrement = (SELECT MIN(R2.dtDate_Enregistrement)
										 FROM tblOPER_OperationsRIO R2
										 WHERE R2.iID_Convention_Source = R.iID_Convention_Source AND
											   R2.bRIO_Annulee = 0 AND
											   R2.bRIO_QuiAnnule = 0)
		  -- qui ont un solde transférable par le RIO...
		  AND 0 < (SELECT ISNULL(SUM(OC.ConventionOperAmount),0)
					FROM dbo.Un_ConventionOper OC
					WHERE OC.ConventionID = R.iID_Convention_Source
					  AND (CHARINDEX(OC.ConventionOperTypeID,@vcRIO_TRANSFERT_TRANSAC_CONVENTION) > 0))
		  -- qui ont un compte en perte
		  AND /*NOT*/ EXISTS (SELECT CO.ConventionOperTypeID,SUM(CO.ConventionOperAmount)
						  FROM Un_ConventionOper CO
						  WHERE CO.ConventionID = R.iID_Convention_Source
							AND (CHARINDEX(CO.ConventionOperTypeID,@vcRIO_TRANSFERT_TRANSAC_CONVENTION) > 0)
						  GROUP BY CO.ConventionOperTypeID
						  HAVING SUM(CO.ConventionOperAmount) < 0)
			and R.OperTypeID = 'TRI'
		)v
		WHERE (SELECT iElligible FROM dbo.fntOPER_ValiderRetransfertRIO(iID_Convention_Source)) = 1
		
		select * from t2
		where conventionno not in (select conventionno from t1)
		R-20080204012
		*/

