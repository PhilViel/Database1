/********************************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	psCONV_ReleveDeCompte_Populer_tblCONV_ReleveDeCompte_RecensementPCEEerreurL
Description         :	
Valeurs de retours  :	Dataset de données

						

Note                :
	
					2016-08-11	Donald Huppé	Création 
					2018-05-11	Donald Huppé	Version finale utilsée pour relevé de 2017-12-31
					2018-09-07	Maxime Martel	JIRA MP-699 Ajout de OpertypeID COU
exec psCONV_ReleveDeCompte_Populer_tblCONV_ReleveDeCompte_RecensementPCEEerreurL

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ReleveDeCompte_Populer_tblCONV_ReleveDeCompte_RecensementPCEEerreurL] 
AS
BEGIN


-- Script retournant la liste des Bénéficiaires dont le NAS du principal responsable ne 
-- correspond pas au NAS de l'ARC.


DECLARE 
	@StartDate DATETIME,
	@EndDate DATETIME,
	@StartDate36 DATETIME,
	@NoErreur varchar(2)
	
--SET @StartDate = '2005-01-01'
SET @StartDate = '2017-01-01'
SET @EndDate = '2017-12-31'
SET @StartDate36 = '2015-01-01' -- 36 MOIS AVANT L'ENVOI DES RELEVÉS 31 décembre 2015 moins 36 mois (au 1er janvier)

set @NoErreur = 'L'

if exists (select * from sysobjects where name = 'tblCONV_ReleveDeCompte_RecensementPCEEerreurL')
	delete from tblCONV_ReleveDeCompte_RecensementPCEEerreurL --drop table tblCONV_ReleveDeCompte_RecensementPCEEerreurL -- select * from tblCONV_ReleveDeCompte_RecensementPCEEerreurL


/*********************************************************************************/


	SELECT 
		C4.ConventionID
	INTO #tListeBenefL1_1erTransdurandPeriode
	FROM UN_CESP400 C4
    --LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID AND R4.iCESP800ID IS NULL
    LEFT JOIN Un_Convention Co ON C4.ConventionID = Co.ConventionID
    LEFT JOIN Un_Beneficiary B ON B.BeneficiaryID = Co.BeneficiaryID
	LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
	LEFT JOIN UN_CESP900 C9  ON C4.iCESP400ID = C9.iCESP400ID
    /*LEFT JOIN (
		SELECT 
			C9.iCESP400ID,
			ACESG = SUM(C9.fACESG)
		FROM Un_CESP900 C9 
		GROUP BY C9.iCESP400ID
	) C9Sum ON C9Sum.iCESP400ID = C9.iCESP400ID*/
	WHERE C4.iCESPSendFileID IS NOT NULL -- Être envoyé au PCEE
		AND C4.iCESP800ID IS NULL -- Pas en erreur
		--AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
		AND C4.OperID NOT IN(SELECT OperSourceID FROM Un_OperCancelation)-- PAS annulé
		AND Co.bACESGRequested  = 1 -- SCEE+ demandé
		AND Co.bSendToCESP  = 1 -- Doit être envoyée au PCEE
		AND S.iCESPReceiveFileID IS NOT NULL -- Avoir reçu une réponse
		AND C9.cCESP900ACESGReasonID = @NoErreur -- Le NAS ne correspond pas avec celui de l'ARC
		--AND R4.iCESP400ID IS NULL -- Pas annulé
		--AND C9Sum.ACESG = 0 -- Pas de SCEE+ versé
		
		AND ISNULL(C4.vcPCGFirstName,'') = ISNULL(B.vcPCGFirstName,'') -- Le responsable doit être le même que celui envoyé lors de l'erreur
		AND ISNULL(C4.vcPCGLastName,'') = ISNULL(B.vcPCGLastName,'')
		AND ISNULL(C4.vcPCGSINorEN,'') = ISNULL(B.vcPCGSINorEN,'')
		AND ISNULL(C4.tiPCGType,'') = ISNULL(B.tiPCGType,'')
	GROUP by C4.ConventionID
	--HAVING min(C4.dtTransaction) BETWEEN @StartDate AND @EndDate
	HAVING min(C4.dtTransaction) <= @EndDate



	-- Liste des conventions avec au moins une erreur '4' en cours
	SELECT 
		C4.ConventionID,
		Co.BeneficiaryID,
		C4.iCESP400ID,
		C4.CotisationID
	INTO #tListeBenefL1
	FROM UN_CESP400 C4
	join #tListeBenefL1_1erTransdurandPeriode mm on c4.ConventionID = mm.ConventionID
    --LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID AND R4.iCESP800ID IS NULL
    LEFT JOIN Un_Convention Co ON C4.ConventionID = Co.ConventionID
    LEFT JOIN Un_Beneficiary B ON B.BeneficiaryID = Co.BeneficiaryID
	LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
	LEFT JOIN UN_CESP900 C9  ON C4.iCESP400ID = C9.iCESP400ID
    /*LEFT JOIN (
		SELECT 
			C9.iCESP400ID,
			ACESG = SUM(C9.fACESG)
		FROM Un_CESP900 C9 
		GROUP BY C9.iCESP400ID
	) C9Sum ON C9Sum.iCESP400ID = C9.iCESP400ID*/
	WHERE C4.iCESPSendFileID IS NOT NULL -- Être envoyé au PCEE
		AND C4.iCESP800ID IS NULL -- Pas en erreur
		--AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
		AND C4.OperID NOT IN(SELECT OperSourceID FROM Un_OperCancelation)-- PAS annulé
		AND Co.bACESGRequested  = 1 -- SCEE+ demandé
		AND Co.bSendToCESP  = 1 -- Doit être envoyée au PCEE
		AND S.iCESPReceiveFileID IS NOT NULL -- Avoir reçu une réponse
		AND C9.cCESP900ACESGReasonID = @NoErreur -- Le NAS ne correspond pas avec celui de l'ARC
		--AND R4.iCESP400ID IS NULL -- Pas annulé
		--AND C9Sum.ACESG = 0 -- Pas de SCEE+ versé
		
		AND ISNULL(C4.vcPCGFirstName,'') = ISNULL(B.vcPCGFirstName,'') -- Le responsable doit être le même que celui envoyé lors de l'erreur
		AND ISNULL(C4.vcPCGLastName,'') = ISNULL(B.vcPCGLastName,'')
		AND ISNULL(C4.vcPCGSINorEN,'') = ISNULL(B.vcPCGSINorEN,'')
		AND ISNULL(C4.tiPCGType,'') = ISNULL(B.tiPCGType,'')
		
		--AND C4.dtTransaction BETWEEN @StartDate AND @EndDate
		AND C4.dtTransaction <= @EndDate
		

	GROUP BY 
		C4.ConventionID,
		Co.BeneficiaryID,
		C4.iCESP400ID,
		C4.CotisationID
	ORDER BY
		C4.ConventionID,
		Co.BeneficiaryID,
		C4.iCESP400ID,
		C4.CotisationID

	CREATE index #i1 on #tListeBenefL1(conventionid)
	CREATE index #i2 on #tListeBenefL1(iCESP400ID)


	--select DISTINCT ConventionID FROM #tListeBenefL1 --where BeneficiaryID = 241388

	-- Liste des conventions avec une erreur différente après l'erreur @NoErreur
	-- et dont la DERNIÈRE erreur est différente de NoErreur
	SELECT 
		C9.iCESP400ID,
		ACESG = SUM(C9.fACESG)
	INTO #ACESG
	FROM Un_CESP900 C9 
	join #tListeBenefL1 t on t.conventionid = C9.ConventionID
	JOIN (
		SELECT DISTINCT f.iCESP400ID
		from un_cesp900 f
		join #tListeBenefL1 t on t.conventionid = f.ConventionID
		) c44 ON c44.iCESP400ID = C9.iCESP400ID
	GROUP BY C9.iCESP400ID

	-- select count(*) from #ACESG

	CREATE index #ind_ACESG on #ACESG(iCESP400ID)

	SELECT 
		--C4.*,
		C4.ConventionID
		
		--,Co.BeneficiaryID,
		--C4.iCESP400ID,
		--C4.dtTransaction,
		--C9.cCESP900ACESGReasonID
		
	INTO #tListeBenefL -- drop table #tListeBenefL
	FROM UN_CESP400 C4
	JOIN #tListeBenefL1 L ON L.ConventionID = C4.ConventionID AND C4.iCESP400ID > L.iCESP400ID
	LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID AND R4.iCESP800ID IS NULL
	LEFT JOIN Un_Convention Co ON C4.ConventionID = Co.ConventionID
	LEFT JOIN Un_Beneficiary B ON B.BeneficiaryID = Co.BeneficiaryID
	LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
	LEFT JOIN UN_CESP900 C9  ON C4.iCESP400ID = C9.iCESP400ID
	LEFT JOIN #ACESG C9Sum ON C9Sum.iCESP400ID = C9.iCESP400ID
			
			
	left JOIN ( -- benef avec dernière raison de réponse reçu = @NoErreur
		SELECT distinct cc.BeneficiaryID
		from Un_CESP900 c9
		JOIN Un_Convention cc ON c9.ConventionID = cc.ConventionID
		join (
			SELECT c4.conventionid, iCESP900ID = max(C9.iCESP900ID)
			FROM 
				UN_CESP400 C4
				JOIN Un_Convention Co ON C4.ConventionID = Co.ConventionID
				JOIN Un_Beneficiary B ON B.BeneficiaryID = Co.BeneficiaryID
				JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
				JOIN UN_CESP900 C9  ON C4.iCESP400ID = C9.iCESP400ID 
				join #tListeBenefL1 t on t.conventionid = c9.ConventionID
			where C4.dtTransaction <= @EndDate
			GROUP BY c4.conventionid
			) mc9 ON c9.iCESP900ID = mc9.iCESP900ID and c9.conventionid = mc9.conventionid
		WHERE c9.cCESP900ACESGReasonID = @NoErreur
			) l4 ON l4.BeneficiaryID = co.BeneficiaryID
				

			
	WHERE 
			(
			1=1
			and C4.iCESPSendFileID IS NOT NULL -- Être envoyé au PCEE
			AND C4.iCESP800ID IS NULL -- Pas en erreur
			AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
			AND C4.OperID NOT IN(SELECT OperSourceID FROM Un_OperCancelation)-- PAS annulé
			AND Co.bACESGRequested  = 1 -- SCEE+ demandé
			AND Co.bSendToCESP  = 1 -- Doit être envoyée au PCEE
			AND S.iCESPReceiveFileID IS NOT NULL -- Avoir reçu une réponse
			AND C9.cCESP900ACESGReasonID IN ('1', '2', '3', '4', '5', '6', '7', '9', 'B', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'M', 'N') -- Le NAS ne correspond pas avec celui de l'ARC
			AND R4.iCESP400ID IS NULL -- Pas annulé
			AND isnull(C9Sum.ACESG,0) = 0 -- Pas de SCEE+ versé
			
			AND ISNULL(C4.vcPCGFirstName,'') = ISNULL(B.vcPCGFirstName,'') -- Le responsable doit être le même que celui envoyé lors de l'erreur
			AND ISNULL(C4.vcPCGLastName,'') = ISNULL(B.vcPCGLastName,'')
			AND ISNULL(C4.vcPCGSINorEN,'') = ISNULL(B.vcPCGSINorEN,'')
			AND ISNULL(C4.tiPCGType,'') = ISNULL(B.tiPCGType,'')
	
			and l4.BeneficiaryID IS null -- benef avec dernière raison de réponse reçu doit être différent de @NoErreur
			
			and C4.dtTransaction <= @EndDate
			
			)



		--and Co.ConventionNo = 'R-20071219018'
		--and Co.BeneficiaryID = 632747
		
	GROUP BY C4.ConventionID
	
		--,Co.BeneficiaryID,
		--C4.iCESP400ID,
		--C4.dtTransaction,
		--C9.cCESP900ACESGReasonID

	
	
	

	

/****************************************************************************************************/

	--SELECT t1= '1',* FROM #tListeBenefL --where  conventionid in (SELECT conventionid from un_convention WHERE  BeneficiaryID = 241388)
	
	--return

	-- ici -- 20 minutes

	-- Liste des conventions avec au moins une erreur '4' en cours
	SELECT 
		C4.ConventionID,
		Co.BeneficiaryID
	INTO #tListeBenef
	FROM UN_CESP400 C4
	join #tListeBenefL1_1erTransdurandPeriode mm on c4.ConventionID = mm.ConventionID
	LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID AND R4.iCESP800ID IS NULL
	LEFT JOIN Un_Convention Co ON C4.ConventionID = Co.ConventionID
	LEFT JOIN Un_Beneficiary B ON B.BeneficiaryID = Co.BeneficiaryID
	LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
	LEFT JOIN UN_CESP900 C9  ON C4.iCESP400ID = C9.iCESP400ID
	LEFT JOIN ( -- Vérifier que cette convention n'a pas été subventionnée après cet erreur
		SELECT 
			C9.ConventionID,
			ACESG = SUM(C9.fACESG)
		FROM 
			Un_CESP900 C9 
			-- chg ajout 2015-11-30
			join Un_CESP400 c4 on c9.iCESP400ID = c4.iCESP400ID
			join #tListeBenefL1_1erTransdurandPeriode mm on c4.ConventionID = mm.ConventionID
			------------
			JOIN (
				SELECT DISTINCT c9.iCESP400ID
				from un_cesp900 c9
				-- chg ajout 2015-11-30
				join Un_CESP400 c4 on c9.iCESP400ID = c4.iCESP400ID
				join #tListeBenefL1_1erTransdurandPeriode mm on c4.ConventionID = mm.ConventionID
				------------
				where c9.cCESP900ACESGReasonID = @NoErreur
				) c44 ON c44.iCESP400ID = C9.iCESP400ID
		
		GROUP BY C9.ConventionID
	) C9Sum ON C9Sum.ConventionID = Co.ConventionID

	JOIN ( -- Vérifier que la convention a au moins une cotisation dans les 36 dernier mois
		SELECT 
			U.ConventionID
		FROM Un_Cotisation ct
		JOIN Un_Unit U ON U.UnitID = ct.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		join #tListeBenefL1_1erTransdurandPeriode mm on u.ConventionID = mm.ConventionID -- chg ajout 2015-11-30
		WHERE ct.EffectDate BETWEEN @StartDate36 AND @EndDate -->= @StartDate36
			AND O.OperTypeID IN ('CPA','CHQ','PRD','FCB','TFR','RDI','COU')
		GROUP BY U.ConventionID
		) ct ON ct.conventionID = C4.ConventionID
	WHERE C4.iCESPSendFileID IS NOT NULL -- Être envoyé au PCEE
		AND C4.iCESP800ID IS NULL -- Pas en erreur
		AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
		AND C4.OperID NOT IN(SELECT OperSourceID FROM Un_OperCancelation)-- PAS annulé
		AND Co.bACESGRequested  = 1 -- SCEE+ demandé
		AND Co.bSendToCESP  = 1 -- Doit être envoyée au PCEE
		AND S.iCESPReceiveFileID IS NOT NULL -- Avoir reçu une réponse
		AND C9.cCESP900ACESGReasonID = @NoErreur -- Le NAS ne correspond pas avec celui de l'ARC
		AND R4.iCESP400ID IS NULL -- Pas annulé
		AND C9Sum.ACESG = 0 -- Pas de SCEE+ versé
		AND ISNULL(C4.vcPCGFirstName,'') = ISNULL(B.vcPCGFirstName,'') -- Le responsable doit être le même que celui envoyé lors de l'erreur
		AND ISNULL(C4.vcPCGLastName,'') = ISNULL(B.vcPCGLastName,'')
		AND ISNULL(C4.vcPCGSINorEN,'') = ISNULL(B.vcPCGSINorEN,'')
		AND ISNULL(C4.tiPCGType,'') = ISNULL(B.tiPCGType,'')

		
		--AND C4.dtTransaction BETWEEN @StartDate AND @EndDate
		AND C4.dtTransaction <= @EndDate
		
		
		--and Co.ConventionNo = 'R-20071219018'
		--and (Co.BeneficiaryID = 241388)
		
	GROUP BY 
		C4.ConventionID,
		Co.BeneficiaryID



--SELECT  t2= '2',* from #tListeBenef  where BeneficiaryID = 241388

--return
-- voir mail de M komenda : "3e commentaire recensement 4, M et L 2012"
-- Détruire les cas réglé : quand la dernière réponse est 0 et qu'on recoit de la SCEE+
DELETE #TListeBenef
--SELECT * 
FROM #TListeBenef LB
join Un_CESP400 c4 on c4.ConventionID = LB.ConventionID
join (
	SELECT c4.ConventionID,  MAX_iCESP400ID =  MAX(c4.iCESP400ID)
	FROM #TListeBenef LB
	join Un_CESP400 c4 on c4.ConventionID = LB.ConventionID
	join un_cesp900 c9 on c9.iCESP400ID = c4.iCESP400ID 
	GROUP by c4.ConventionID
	)mc4 on c4.iCESP400ID = mc4.MAX_iCESP400ID
join un_cesp900 c9 on c9.iCESP400ID = c4.iCESP400ID AND c9.cCESP900ACESGReasonID = '0' AND c9.fACESG > 0

-- Détruire les cas réglé : ont recu du scee+ après la date de fin
DELETE #TListeBenef
--SELECT * 
FROM #TListeBenef LB
join Un_CESP400 c4 on c4.ConventionID = LB.ConventionID
join un_cesp900 c9 on c9.iCESP400ID = c4.iCESP400ID AND c9.cCESP900ACESGReasonID = 0 AND c9.fACESG > 0
where c4.dtTransaction > @EndDate 

-- Supprime les transférés OUT
DELETE #TListeBenef
FROM #TListeBenef CB
JOIN Un_Unit U ON U.ConventionID = CB.ConventionID
JOIN Un_Cotisation CO ON CO.UnitID = U.UnitID
JOIN Un_Oper O ON O.OperID = CO.OperID
WHERE O.OperTypeID = 'OUT'

--SELECT  t3= '3',* from #tListeBenef  --where BeneficiaryID = 511745

-- Supprime les conventions résiliées
DELETE #TListeBenef
FROM #TListeBenef CB
JOIN Un_Unit U ON U.ConventionID = CB.ConventionID
WHERE U.TerminatedDate IS NOT NULL
	OR U.IntReimbDate IS NOT NULL -- Uniquement pour les relevés de dépôt

--SELECT  t4= '4',* from #tListeBenef  --where BeneficiaryID = 511745

-- Exclue les conventions avec un RI et une rennonciation
DELETE #TListeBenef -- select * from #TListeBenef
FROM #TListeBenef CB
JOIN Un_Unit U ON U.ConventionID = CB.ConventionID			  
JOIN Un_IntReimb RI ON RI.UnitID = U.UnitID
WHERE U.IntReimbDate IS NOT NULL
   AND CESGRenonciation = 1
   
--SELECT  t5= '5',* from #tListeBenef --where BeneficiaryID = 511745

-- Exclu les conventions avec un RI, sans SCEE de base reçue à la date de ce RI 
DELETE #TListeBenef
FROM #TListeBenef CB
JOIN Un_Unit U ON U.ConventionID = CB.ConventionID
LEFT JOIN (	
	SELECT 
		C4.ConventionID,
		fCESG = SUM(
			CASE 
				WHEN C4.iReversedCESP400ID IS NOT NULL THEN ISNULL(C9.fCESG,-ISNULL(CE.fCESG,0))
			ELSE ISNULL(C9.fCESG,ISNULL(CE.fCESG,0))
			END)  -- SCEE.
	FROM Un_CESP400 C4
	JOIN Un_Unit U ON U.ConventionID = C4.ConventionID
	join #TListeBenef CB ON U.ConventionID = CB.ConventionID -- chg ajout 2015-11-30
	JOIN Un_Oper O ON O.OperID = C4.OperID
	LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
	LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
	LEFT JOIN Un_CESPReceiveFile R ON R.iCESPReceiveFileID = ISNULL(C9.iCESPReceiveFileID,S.iCESPReceiveFileID)
	LEFT JOIN Un_CESP CE ON (CE.OperID = O.OperID AND CE.ConventionID = C4.ConventionID) 
	LEFT JOIN Un_Oper OS ON OS.OperID = R.OperID
	WHERE OS.OperDate <= U.IntReimbDate
	GROUP BY C4.ConventionID
	) CE ON CE.ConventionID = CB.ConventionID
WHERE U.IntReimbDate IS NOT NULL
	AND ISNULL(CE.fCESG,0) = 0




-- Supprimer les conventions avec une réponse DIFFÉRENTE après une réponse @NoErreur
DELETE #TListeBenef
FROM #TListeBenef CB
JOIN #TListeBenefL CBL ON CBL.ConventionID = CB.ConventionID



/*
SELECT distinct co.BeneficiaryID
into #todel
FROM 
	UN_CESP400 C4
	JOIN Un_Convention Co ON C4.ConventionID = Co.ConventionID
	JOIN Un_Beneficiary B ON B.BeneficiaryID = Co.BeneficiaryID
	JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
	JOIN UN_CESP900 C9  ON C4.iCESP400ID = C9.iCESP400ID 
	join (SELECT DISTINCT conventionid from #tListeBenefL1) t on t.conventionid = c9.ConventionID
where c9.cCESP900ACESGReasonID = @NoErreur
GROUP BY co.BeneficiaryID
HAVING min(C4.dtTransaction) BETWEEN @StartDate AND @EndDate
			

-- Supprimer les bénèf dont l'erreur n'a pas débuté dans la plage de date
-- ici : à enlever
delete from #TListeBenef WHERE BeneficiaryID NOT IN (SELECT BeneficiaryID from #todel)
*/		


--DECLARE 
--	@StartDate DATETIME,
--	@EndDate DATETIME,
--	@StartDate36 DATETIME,
--	@NoErreur varchar(2)
	
----SET @StartDate = '2005-01-01'
--SET @StartDate = '2015-01-01'
--SET @EndDate = '2015-12-31'
--SET @StartDate36 = '2013-01-01'
-- Final
insert into tblCONV_ReleveDeCompte_RecensementPCEEerreurL
SELECT DISTINCT
	RecuArgentEnsuite = CASE WHEN moneyAfter.BeneficiaryID IS NOT NULL THEN 'X' ELSE '' END,
	C.BeneficiaryID,
	NomBeneficiaire = HB.LastName,
	PrenomBeneficiaire = HB.FirstName,
	DateNaissanceBenef = hb.birthdate,
	NomSouscripteur = HS.LastName,
	PrenomSouscripteur = HS.FirstName,
	C.SubscriberID,
	HS.SexID,
	SEX.LongSexName,
	SEX.ShortSexName,
	HS.LangID,
	A.Address,
	A.City,
	A.StateName,
	A.CountryID,
	CASE LEN(A.ZipCode) WHEN 6 THEN LEFT(A.ZipCode, 3) + ' ' + RIGHT(A.ZipCode, 3) ELSE A.ZipCode END AS CodePostal,
	C.ConventionNo,
	V1_ConventionStateID = V1.ConventionStateID,
	V2_ConventionStateID = V2.ConventionStateID,
	B.vcPCGLastName,
	B.vcPCGFirstName,
	B.vcPCGSINorEN,
	--B.tiPCGType,
	RelationBeneficiaireVSSouscripteur = RT.vcRelationshipType,
	NomRep = HR.LastName,
	PrenomRep = HR.FirstName 
--into tblCONV_ReleveDeCompte_RecensementPCEEerreurL
FROM #tListeBenef LB
	/*
	(
	-- Va chercher la convention créée en dernier pour un bénéficiaire, 
	-- selon le lien de parenté le plus proche trouvé
	SELECT 
		CB.BeneficiaryID,
		DerniereConv = MAX(C.ConventionID)
	FROM ( -- Va chercher le lien de parenté le plus proche du bénéficiaire	
		SELECT 
			C.BeneficiaryID,
			tiRelationshipTypeID = MIN(C.tiRelationshipTypeID)
		FROM #TListeBenef CB
		--JOIN Un_Convention C ON C.ConventionID = CB.ConventionID
		JOIN Un_Convention C ON C.BeneficiaryID = CB.BeneficiaryID
		join (
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
					--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= '2011-10-31' -- Si je veux l'état à une date précise 
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
			) css on C.conventionid = css.conventionid
		JOIN Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		WHERE S.AddressLost = 0 -- Adresse non perdue
		--and C.BeneficiaryID = 290842
		GROUP BY C.BeneficiaryID
		) RT
	JOIN #TListeBenef CB ON CB.BeneficiaryID = RT.BeneficiaryID
	--JOIN Un_Convention C ON C.ConventionID = CB.ConventionID
	JOIN Un_Convention C ON C.BeneficiaryID = CB.BeneficiaryID AND C.tiRelationshipTypeID = RT.tiRelationshipTypeID
	join (
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
				--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= '2011-10-31' -- Si je veux l'état à une date précise 
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
		) css on C.conventionid = css.conventionid
	JOIN Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	WHERE S.AddressLost = 0 
	--and CB.BeneficiaryID = 290842-- Adresse non perdue 
	GROUP BY CB.BeneficiaryID
	) BR 
	*/
JOIN Un_Convention C ON C.ConventionID = LB.ConventionID -- BR.DerniereConv
JOIN Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
JOIN Mo_Human HB ON HB.HumanID = B.BeneficiaryID
JOIN Mo_Human HS ON HS.HumanID = C.SubscriberID
JOIN Un_subscriber S ON S.SubscriberID = C.SubscriberID
JOIN Mo_Human HR ON HR.HumanID = S.RepID
JOIN Mo_Sex SEX ON SEX.SexID = HS.SexID AND SEX.LangID = HS.LangID
JOIN Mo_Adr A ON A.AdrID = HS.AdrID
JOIN Un_RelationshipType RT ON RT.tiRelationshipTypeID = C.tiRelationshipTypeID



LEFT JOIN (
	SELECT 
		V.ConventionID,
		CCS.ConventionStateID
	FROM ( -- Retourne le plus grand ID pour la plus grande date de début d'un état par convention
		SELECT 		
			T.ConventionID,
			ConventionConventionStateID = MAX(CCS.ConventionConventionStateID)
		FROM (-- Retourne la plus grande date de début d'un état par convention
			SELECT 
				S.ConventionID,
				MaxDate = MAX(S.StartDate)
			FROM Un_ConventionConventionState S
			JOIN Un_Convention C ON C.ConventionID = S.ConventionID
			WHERE S.StartDate <= @EndDate -- État à la date de fin de la période
			GROUP BY S.ConventionID
			) T
		JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
		GROUP BY T.ConventionID
		) V
	JOIN Un_ConventionConventionState CCS ON V.ConventionConventionStateID = CCS.ConventionConventionStateID
	) V1 ON V1.ConventionID = C.ConventionID
LEFT JOIN (
	SELECT 
		V.ConventionID,
		CCS.ConventionStateID
	FROM ( -- Retourne le plus grand ID pour la plus grande date de début d'un état par convention
		SELECT 		
			T.ConventionID,
			ConventionConventionStateID = MAX(CCS.ConventionConventionStateID)
		FROM (-- Retourne la plus grande date de début d'un état par convention
			SELECT 
				S.ConventionID,
				MaxDate = MAX(S.StartDate)
			FROM Un_ConventionConventionState S
			JOIN Un_Convention C ON C.ConventionID = S.ConventionID
			WHERE S.StartDate <= GETDATE()--@dtEnd -- État à la date de fin de la période
			GROUP BY S.ConventionID
			) T
		JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
		GROUP BY T.ConventionID
		) V
	JOIN Un_ConventionConventionState CCS ON V.ConventionConventionStateID = CCS.ConventionConventionStateID
	) V2 ON V2.ConventionID = C.ConventionID
	
LEFT JOIN (
	SELECT distinct co.BeneficiaryID
	FROM 
		UN_CESP400 C4
		JOIN Un_Convention Co ON C4.ConventionID = Co.ConventionID
		JOIN Un_Beneficiary B ON B.BeneficiaryID = Co.BeneficiaryID
		JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
		JOIN UN_CESP900 C9  ON C4.iCESP400ID = C9.iCESP400ID 
		--join (SELECT DISTINCT conventionid from #tListeBenefL1) t on t.conventionid = c9.ConventionID
		join #tListeBenefL1 t on t.conventionid = c9.ConventionID
	where C4.dtTransaction > @EndDate
	GROUP BY co.BeneficiaryID
	HAVING sum(C9.fACESG)> 0
		)moneyAfter ON moneyAfter.BeneficiaryID = C.BeneficiaryID	
	
ORDER BY 
	HB.LastName,
	HB.FirstName,
	HS.LastName,
	HS.FirstName		




END