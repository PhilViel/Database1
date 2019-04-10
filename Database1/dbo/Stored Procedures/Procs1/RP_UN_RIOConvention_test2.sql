/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RIOConvention
Description         :	Rapport : Détails des RIO faits sur les groupes d'unités entre deux dates sélectionnées 
Valeurs de retours  :	Dataset :
					iID_Oper_RIO	INTEGER		ID de l'opération RIO			
					dtDate_Enregistrement DATETIME	Date de l'enregistrement du RIO
					FirstName		VARCHAR(35)	Prénom du souscripteur
					LastName		VARCHAR(50)	Nom de famille du souscripteur
					ConventionNo	VARCHAR(15)	Numéro de la convention source
					InForceDate		DATETIME	Date d'entrée en vigeur du groupe d'unité source
					UnitQty			MONEY		Nombre d'unité du groupe d'unité source	
					SCotisation		MONEY		Montant de cotisations transféré
					SFrais			MONEY		Montant de frais transféré
					SSCEE			MONEY		Montant de SCEE transféré
					SSCEEPlus		MONEY		Montant de SCEE+ transféré
					SBEC			MONEY		Montant de BEC transféré
					SInt			MONEY		Montant d'intérêts transféré
					ConventionNo	VARCHAR(15)	Numéro de la convention créée lors du RIO
					DCotisation		MONEY		Montant de cotisations reçu
					DFrais			MONEY		Montant de frais reçu
					DSCEE			MONEY		Montant de SCEE reçu
					DSCEEPlus		MONEY		Montant de SCEE+ reçu
					DBEC			MONEY		Montant de BEC reçu
					DInt			MONEY		Montant d'intérêt reçu
					Somme			MONEY		Somme de tous les montants du RIO pour vérifier que tout balance
					FraisTransfEpargne	MONEY	Montant des frais transférés à l'épargne

Note                :			2008-08-20	Pierre-Luc Simard		Création
								2009-12-17	Donald Huppé			Ajout de l'IQEE
								2010-03-31	Donald Huppé			Mettre un filtre pour que sorte seulement les transfert avec montant <> 0
																	car depusi ce mois, des opération avec montant à 0 apparaissent

exec RP_UN_RIOConvention '2010-03-01', '2010-03-31'
select * from un_reptreatment
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RIOConvention_test2] (	
	@dtStart DATETIME, -- Date de début saisie
	@dtEnd DATETIME) -- Date de fin saisie
AS
BEGIN
	SELECT 
		R.iID_Oper_RIO, -- ID de l'opération RIO			
		dtDate_Enregistrement = convert(varchar(10),O.OperDate,120), -- Date de l'enregistrement du RIO
		HS.FirstName, -- Prénom du souscripteur
		HS.LastName, -- Nom de famille du souscripteur
		SConventionNo = CS.ConventionNo, -- Numéro de la convention source
		InForceDate = convert(varchar(10),US.InForceDate,120), -- Date d'entrée en vigeur du groupe d'unité source
		US.UnitQty, -- Nombre d'unité du groupe d'unité source	
		SCotisation = ISNULL(CO1.Cotisation,0), -- Montant de cotisations transféré
		SFrais = ISNULL(CO1.Fee,0), -- Montant de frais transféré
		SSCEE = ISNULL(CES.fCESG,0), -- Montant de SCEE transféré
		SSCEEPlus = ISNULL(CES.fACESG,0), -- Montant de SCEE+ transféré
		SBEC = ISNULL(CES.fCLB,0), -- Montant de BEC transféré
		SInt = ISNULL(OC.SInt,0), -- Montant d'intérêts transféré
		
		SIQEE =	ISNULL(IQEES.IQEE,0),
        SRendIQEE = ISNULL(IQEES.RendIQEE,0),
        SIQEEMaj = ISNULL(IQEES.IQEEMaj,0),
        SRendIQEEMaj = ISNULL(IQEES.RendIQEEMaj,0),
        SRendIQEETin = ISNULL(IQEES.RendIQEETin,0),
        
		DConventionNo = CD.ConventionNo, -- Numéro de la convention créée lors du RIO
		DCotisation = ISNULL(CO2.Cotisation,0), -- Montant de cotisations reçu
		DFrais = ISNULL(CO2.Fee,0), -- Montant de frais reçu
		DSCEE = ISNULL(CED.fCESG,0), -- Montant de SCEE reçu
		DSCEEPlus = ISNULL(CED.fACESG,0), -- Montant de SCEE+ reçu
		DBEC = ISNULL(CED.fCLB,0), -- Montant de BEC reçu
		DInt = ISNULL(OCD.DInt,0), -- Montant d'intérêt reçu

		DIQEE =	ISNULL(IQEED.IQEE,0),
        DRendIQEE = ISNULL(IQEED.RendIQEE,0),
        DIQEEMaj = ISNULL(IQEED.IQEEMaj,0),
        DRendIQEEMaj = ISNULL(IQEED.RendIQEEMaj,0),
  DRendIQEETin = ISNULL(IQEED.RendIQEETin,0),

		Somme =  -- Somme de tous les montants du RIO pour vérifier que tout balance
			ISNULL(CO1.Cotisation,0) 
			+ ISNULL(CO1.Fee,0) 
			+ ISNULL(CES.fCESG,0) 
			+ ISNULL(CES.fACESG,0) 
			+ ISNULL(CES.fCLB,0) 
			+ ISNULL(OC.SInt,0) 
			+ ISNULL(CO2.Cotisation,0) 
			+ ISNULL(CO2.Fee,0)
			+ ISNULL(CED.fCESG,0) 
			+ ISNULL(CED.fACESG,0) 
			+ ISNULL(CED.fCLB,0) 
			+ ISNULL(OCD.DInt,0),
		FraisTransfEpargne = ABS(ISNULL(CO1.Fee,0))-ISNULL(CO2.Fee,0) -- Montant des frais transférés à l'épargne
	FROM tblOPER_OperationsRIO R
	JOIN dbo.Un_Convention CS ON CS.ConventionID = R.iID_Convention_Source
	JOIN dbo.Un_Unit US ON US.UnitID = R.iID_Unite_Source
	JOIN dbo.Mo_Human HS ON HS.HumanID = CS.SubscriberID
	JOIN dbo.Un_Convention CD ON CD.ConventionID = R.iID_Convention_Destination
	JOIN dbo.Un_Unit UD ON UD.UnitID = R.iID_Unite_Destination
	JOIN Un_Oper O ON O.OperID = R.iID_Oper_RIO
	
	LEFT JOIN (	
		select OC.OperSourceID 
		from Un_OperCancelation OC 
		join un_oper op2 on OC.OperID = Op2.OperID
		where op2.operdate > @dtEnd
				) CancelRIO on R.iID_Oper_RIO = CancelRIO.OperSourceID
	
	LEFT JOIN Un_Cotisation CO1 ON CO1.UnitID = R.iID_Unite_Source AND CO1.OperID = R.iID_Oper_RIO
	LEFT JOIN Un_Cotisation CO2 ON CO2.UnitID = R.iID_Unite_Destination AND CO2.OperID = R.iID_Oper_RIO
	LEFT JOIN Un_CESP CES ON CES.ConventionID = R.iID_Convention_Source AND CES.OperID = R.iID_Oper_RIO
	LEFT JOIN Un_CESP CED ON CED.ConventionID = R.iID_Convention_Destination AND CED.OperID = R.iID_Oper_RIO
	LEFT JOIN ( -- Intérêts PCEE transférés pour chaque opération RIO
		SELECT 
			ConventionID, 
			OperID,
			SInt = ISNULL(SUM(ConventionOperAmount),0)
		FROM Un_ConventionOper
		WHERE ConventionOperTypeID IN ('INS','IS+','IBC','IST')  -- select * from Un_ConventionOper
		GROUP BY 
			ConventionID, 
			OperID
		) OC ON OC.ConventionID = R.iID_Convention_Source AND OC.OperID = R.iID_Oper_RIO
	LEFT JOIN ( -- Intérêts reçus pour chaque opération RIO
		SELECT 
			ConventionID, 
			OperID,
			DInt = ISNULL(SUM(ConventionOperAmount),0)
		FROM Un_ConventionOper  
		WHERE ConventionOperTypeID IN ('INS','IS+','IBC','IST')
		GROUP BY 
			ConventionID, 
			OperID
		) OCD ON OCD.ConventionID = R.iID_Convention_Destination AND OCD.OperID = R.iID_Oper_RIO	
	LEFT JOIN (
		select
			conventionid,
			operid, --
            IQEE = SUM ( -- IQEE
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'CBQ' THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            RendIQEE = SUM ( -- Rendement d'IQEE
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') IN ('ICQ', 'MIM', 'IIQ') THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            IQEEMaj = SUM ( -- Majoration (IQEE +)
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'MMQ' THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            RendIQEEMaj = SUM ( -- Rendement de majoration (IQEE+)
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'IMQ' THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            RendIQEETin = SUM ( -- Rendement IQEE provenant d'un TIN
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') IN ('III', 'IQI') THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            OperInt     = SUM ( -- Tous sauf l'IQEEE
                 CASE
						WHEN ISNULL(UCO.ConventionOperTypeID,'') NOT IN ('CBQ', 'ICQ', 'MIM', 'IIQ', 'MMQ', 'IMQ', 'III', 'IQI') THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
             )
        from Un_ConventionOper UCO
		group by conventionid,operid 
		) IQEES ON O.operid = IQEES.operid and CS.Conventionid = IQEES.conventionID
	LEFT JOIN (
		select
			conventionid,
			operid, --
            IQEE = SUM (
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'CBQ' THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            RendIQEE = SUM (
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') IN ('ICQ', 'MIM', 'IIQ') THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            IQEEMaj = SUM (
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'MMQ' THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            RendIQEEMaj = SUM (
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'IMQ' THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            RendIQEETin = SUM (
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') IN ('III', 'IQI') THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            OperInt     = SUM ( -- Tous sauf l'IQEEE
                 CASE
						WHEN ISNULL(UCO.ConventionOperTypeID,'') NOT IN ('CBQ', 'ICQ', 'MIM', 'IIQ', 'MMQ', 'IMQ', 'III', 'IQI') THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 )
        from Un_ConventionOper UCO
		group by conventionid,operid 
		) IQEED ON O.operid = IQEED.operid and CD.Conventionid = IQEED.conventionID
	WHERE 
		1=1
		--AND R.bRIO_Annulee = 0 -- Pas annulé
		--AND R.bRIO_QuiAnnule = 0 -- Pas une annulation
		AND O.OperDate BETWEEN @dtStart AND @dtEnd -- Date de l'opération RIO dans la période choisie
		AND CancelRIO.OperSourceID is NULL
		AND (
			/*DCotisation =*/ ISNULL(CO2.Cotisation,0) <> 0 OR
			/*DFrais =*/ ISNULL(CO2.Fee,0) <> 0 OR
			/*DSCEE =*/ ISNULL(CED.fCESG,0) <> 0 OR
			/*DSCEEPlus =*/ ISNULL(CED.fACESG,0) <> 0 OR
			/*DBEC =*/ ISNULL(CED.fCLB,0) <> 0 OR
			/*DInt =*/ ISNULL(OCD.DInt,0) <> 0 OR

			/*DIQEE =*/	ISNULL(IQEED.IQEE,0) <> 0 OR
			/*DRendIQEE =*/ ISNULL(IQEED.RendIQEE,0) <> 0 OR
			/*DIQEEMaj =*/ ISNULL(IQEED.IQEEMaj,0) <> 0 OR
			/*DRendIQEEMaj =*/ ISNULL(IQEED.RendIQEEMaj,0) <> 0 OR
			/*DRendIQEETin =*/ ISNULL(IQEED.RendIQEETin,0) <> 0
			)
	
	ORDER BY 
		convert(varchar(10),O.OperDate,120),
		HS.FirstName,
		HS.LastName,
		CS.ConventionNo
END

-- EXEC RP_UN_RIOConvention '2008-07-01', '2008-07-31'
/*  Sequence de test - par: PLS - 2008-08-20
	EXEC RP_UN_RIOConvention
		@dtStart = '2008-07-01', -- Date de début saisie
		@dtEnd = '2008-07-31' -- Date de fin saisie
*/


