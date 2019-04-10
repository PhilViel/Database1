/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: psPCEE_RapportConformitePCEE_SoldePCEEnonConforme
Nom du service		: Rapport des conventions avec des soldes au PCEE non conforme
But 				: jira ti 7072 7073 7074
Facette				: PCEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psPCEE_RapportConformitePCEE_SoldePCEEnonConforme '2018-09-09'


Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2017-03-10		Donald Huppé						Création du service			
		2017-04-20		Donald Huppé						Changement de règle pour les OUT et ajout de 3 champs DateResil,DateEnvoi,DateReception
		2017-04-27		Donald Huppé						Ajout de RES_60jrs
		2017-10-11		Donald Huppé						jira ti-9587 : ajout des autres contrats fermés avec Solde de SCEE
		2018-01-04		Donald Huppé						Ajouter nouvelle raison résil 44,45,46
		2018-09-12		Donald Huppé						Ajouter les TIO et refaire la ps au complet
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psPCEE_RapportConformitePCEE_SoldePCEEnonConforme] (
	@dtEnDateDu DATETIME
	)
AS
BEGIN

	--SET ARITHABORT ON

	CREATE TABLE #TMP (
		IdTypeRapport INT
		,TypeRapport VARCHAR(200)
		,ConventionNo VARCHAR(40)
		,SoldeSCEE MONEY
		,SoldeSCEE_PLus MONEY
		,SoldeBEC MONEY
		,DateResil DATE
		)


	INSERT INTO #TMP
	SELECT 
		IdTypeRapport = 200
		,TypeRapport = 'Transfert OUT'
		,C.ConventionNo
		,SoldeSCEE = ISNULL(SCEE.SCEE,0)
		,SoldeSCEEPlus = ISNULL(SCEE.SCEEPlus,0)
		,SoldeBEC = ISNULL(SCEE.BEC,0)
		,DateResil
	FROM Un_Convention C
	JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtEnDateDu, NULL) CSS ON CSS.ConventionID = c.ConventionID AND CSS.ConventionStateID IN ('FRM')
	JOIN (
		SELECT DISTINCT ConventionID,DateResil
		FROM (
			SELECT DISTINCT C.ConventionID, DateResil = max(O.OperDate)
			FROM 
				Un_Oper o --ON ol.OperID = o.OperID 
				JOIN Un_Cotisation ct ON o.OperID = ct.OperID
				JOIN Un_Unit u ON ct.UnitID = u.UnitID
				JOIN Un_Convention c ON u.ConventionID = c.ConventionID 
				join Un_Subscriber s on c.SubscriberID = s.SubscriberID
				JOIN Un_OUT oute on oute.OperID = o.OperID
				LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
				LEFT JOIN Un_TIO tio on tio.iOUTOperID = o.OperID
			WHERE TIO.iOUTOperID IS NULL
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL
				and o.OperDate <= @dtEnDateDu
			GROUP BY C.ConventionID

			UNION ALL

			SELECT DISTINCT C.ConventionID, DateResil = max(O.OperDate)
			FROM 
				Un_Convention C
				JOIN Un_ConventionOper CO ON C.ConventionID = CO.ConventionID
				JOIN Un_Oper O ON CO.OperID = O.OperID
				JOIN Un_OUT oute on oute.OperID = o.OperID
				LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
				LEFT JOIN Un_TIO tio on tio.iOUTOperID = o.OperID
			WHERE TIO.iOUTOperID IS NULL
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL
				and o.OperDate <= @dtEnDateDu
			GROUP BY C.ConventionID
			)V 
		)cOUT ON cOUT.ConventionID = C.ConventionID
	LEFT JOIN (
		select 
			conventionid,
			SCEE = sum(fcesg),
			SCEEPlus = sum(facesg),
			BEC = sum(fCLB)
		from un_cesp ce
		join un_oper op on ce.operid = op.operid
		where op.operdate <= @dtEnDateDu
		group by conventionid
		)SCEE on SCEE.conventionid = C.conventionid

	WHERE 
		ISNULL(SCEE.SCEE,0) > 0
		OR ISNULL(SCEE.SCEEPlus,0) > 0
		OR ISNULL(SCEE.BEC,0) > 0



	INSERT INTO #TMP
	SELECT 
		IdTypeRapport = 250
		,TypeRapport = 'TIO'
		,C.ConventionNo
		,SoldeSCEE = ISNULL(SCEE.SCEE,0)
		,SoldeSCEEPlus = ISNULL(SCEE.SCEEPlus,0)
		,SoldeBEC = ISNULL(SCEE.BEC,0)
		,DateResil
	FROM Un_Convention C
	JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtEnDateDu, NULL) CSS ON CSS.ConventionID = c.ConventionID AND CSS.ConventionStateID IN ('FRM')
	JOIN (
		SELECT DISTINCT ConventionID,DateResil
		FROM (
			SELECT DISTINCT C.ConventionID, DateResil = max(O.OperDate)
			FROM 
				Un_Oper o --ON ol.OperID = o.OperID 
				JOIN Un_Cotisation ct ON o.OperID = ct.OperID
				JOIN Un_Unit u ON ct.UnitID = u.UnitID
				JOIN Un_Convention c ON u.ConventionID = c.ConventionID 
				join Un_Subscriber s on c.SubscriberID = s.SubscriberID
				JOIN Un_OUT oute on oute.OperID = o.OperID
				LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
				LEFT JOIN Un_TIO tio on tio.iOUTOperID = o.OperID
			WHERE TIO.iOUTOperID IS NOT NULL
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL
				and o.OperDate <= @dtEnDateDu
			GROUP BY C.ConventionID

			UNION ALL

			SELECT DISTINCT C.ConventionID, DateResil = max(O.OperDate)
			FROM 
				Un_Convention C
				JOIN Un_ConventionOper CO ON C.ConventionID = CO.ConventionID
				JOIN Un_Oper O ON CO.OperID = O.OperID
				JOIN Un_OUT oute on oute.OperID = o.OperID
				LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
				LEFT JOIN Un_TIO tio on tio.iOUTOperID = o.OperID
			WHERE TIO.iOUTOperID IS NOT NULL
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL
				and o.OperDate <= @dtEnDateDu
			GROUP BY C.ConventionID
			)V 
		)cOUT ON cOUT.ConventionID = C.ConventionID
	LEFT JOIN (
		select 
			conventionid,
			SCEE = sum(fcesg),
			SCEEPlus = sum(facesg),
			BEC = sum(fCLB)
		from un_cesp ce
		join un_oper op on ce.operid = op.operid
		where op.operdate <= @dtEnDateDu
		group by conventionid
		)SCEE on SCEE.conventionid = C.conventionid

	WHERE 
		ISNULL(SCEE.SCEE,0) > 0
		OR ISNULL(SCEE.SCEEPlus,0) > 0
		OR ISNULL(SCEE.BEC,0) > 0



	INSERT INTO #TMP
	SELECT 
		IdTypeRapport = 100
		,TypeRapport = 'Résiliation'
		,c.ConventionNo
		,SoldeSCEE = sum(ce.fCESG)
		,SoldeSCEE_PLus = sum(ce.fACESG)
		,SoldeBEC = sum(ce.fCLB)
		,DateResil
	from (

		select U.conventionid,DateResil , NbGrUnit = count(*)
		from un_unit U
		join (
			select conventionid, nbResil = count(*), DateResil = max(terminateddate)
			from un_unit un
			where terminateddate is not null
			group by conventionid
			) Resil on U.conventionid = Resil.conventionid
		group by U.conventionid, Resil.nbResil,Resil.DateResil
		having count(*) = Resil.nbResil
		)REs
	join Un_Convention c on REs.ConventionID = c.ConventionID
	join Un_CESP ce on c.ConventionID = ce.ConventionID
	join Un_Oper o on ce.OperID = o.OperID
	WHERE 
		res.DateResil <= @dtEnDateDu
		and o.OperDate <= @dtEnDateDu
		AND C.ConventionNo NOT IN ( SELECT ConventionNo FROM #TMP WHERE IdTypeRapport IN (200,250)) -- EXCLURE LES OUT ET TIO DÉJÀ TROUVÉ
	GROUP by c.ConventionNo,DateResil
	HAVING
		SUM(ce.fCESG) > 0
		OR SUM(ce.fACESG) > 0
		OR SUM(ce.fCLB) > 0	


	INSERT INTO #TMP
	SELECT 
		IdTypeRapport = 300
		,TypeRapport = 'Solde BEC non multiple de 100'
		,c.ConventionNo
		,SoldeSCEE = NULL
		,SoldeSCEEPlus = NULL
		,SoldeBec = sum(ce.fCLB)
		,DateResil = NULL

	from Un_Convention c
	join Un_CESP ce on c.ConventionID = ce.ConventionID
	join Un_Oper o on  o.OperID = ce.OperID
	where o.operdate <= @dtEnDateDu
	GROUP BY c.ConventionNo
	HAVING 
		SUM(ce.fCLB) > 0
		-- si on divise le solde par 100, ça doit donner un entier, Donc le FLOOR de cette division devrait la même valeur.
		-- Si c'est n'est pas le cas alors ce n'est pas un multiple de 100
		AND
			(
				FLOOR(SUM(ce.fCLB)) / 100.0 
			-		  SUM(ce.fCLB)  / 100.0 
				<> 0

			OR

			SUM(ce.fCLB) > 2000

			)

	INSERT INTO #TMP
	SELECT 
		IdTypeRapport = 400
		,TypeRapport = 'Autres contrats fermés'
		,c.ConventionNo
		,SoldeSCEE = sum(ce.fCESG)
		,SoldeSCEE_PLus = sum(ce.fACESG)
		,SoldeBEC = sum(ce.fCLB)
		,DateResil = CSS.startdate
	from  
		Un_Convention c
		JOIN Un_CESP ce on c.ConventionID = ce.ConventionID
		JOIN Un_Oper o on ce.OperID = o.OperID
		JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtEnDateDu, NULL) CSS ON CSS.ConventionID = c.ConventionID AND CSS.ConventionStateID IN ('FRM')
	WHERE 
		C.ConventionNo NOT IN ( SELECT ConventionNo FROM #TMP ) -- EXCLURE LES OUT ET TIO DÉJÀ TROUVÉ
		AND o.OperDate <= @dtEnDateDu
	GROUP by c.ConventionNo, CSS.startdate
	HAVING
		sum(ce.fCESG) > 0
		OR sum(ce.fACESG) > 0
		Or sum(ce.fCLB) > 0	



	SELECT *
	FROM (
		SELECT DISTINCT
			T.IdTypeRapport
			,T.TypeRapport
			,t.ConventionNo
			,t.SoldeSCEE
			,t.SoldeSCEE_PLus
			,t.SoldeBEC
			,t.DateResil
			,DateEnvoi
			,DateReception = case when res.DateReception > res.DateEnvoi then res.DateReception else NULL end
			,UnitStateID = US.UnitStateName
			,RES_60jrs = case when res60.ConventionID is not null then 1 else 0 end
		from #Tmp t
		join Un_Convention c on t.ConventionNo = c.ConventionNo
		join Un_Unit u on u.ConventionID = c.ConventionID
		join (
			select 
				us.unitid,
				uus.startdate,
				us.UnitStateID
			from 
				Un_UnitunitState us
				join (
					select 
					unitid,
					startdate = max(startDate)
					from un_unitunitstate
					--where startDate < DATEADD(d,1 ,'2014-02-08')
					group by unitid
					) uus on uus.unitid = us.unitid 
						and uus.startdate = us.startdate 
						--and us.UnitStateID in ('epg')
			)uus on uus.unitID = u.UnitID
		JOIN Un_UnitState US ON US.UnitStateID = UUS.UnitStateID
		left join (
	
			SELECT 
				c.ConventionNo
				,DateEnvoi = cast(max(sf.dtCESPSendFile) as date)
				,DateReception = cast( max(rf.dtRead) as date)
				--,c4.*
				--,o.OperTypeID
			FROM 
				Un_Convention c
				join #Tmp t1 on t1.ConventionNo = c.ConventionNo
				join Un_CESP400 c4 on c4.ConventionID = c.ConventionID and c4.tiCESP400TypeID = 21 and c4.tiCESP400WithdrawReasonID = 3
				join un_oper o on o.OperID = c4.OperID and o.OperTypeID in( 'RES','OUT')
				left join Un_CESP900 c9	on c9.iCESP400ID = c4.iCESP400ID
				left join Un_CESPSendFile sf on sf.iCESPSendFileID = c4.iCESPSendFileID
				left join Un_CESPReceiveFile rf on rf.iCESPReceiveFileID = c9.iCESPReceiveFileID
			--where c.ConventionNo = 'C-20000713010'
			GROUP BY c.ConventionNo
			)res on res.ConventionNo = t.ConventionNo

		LEFT join (
			select DISTINCT u.ConventionID
			from Un_Unit u
			join Un_Convention c on c.ConventionID = u.ConventionID
			join #Tmp t1 on t1.ConventionNo = c.ConventionNo
			join Un_UnitReduction ur on u.UnitID = ur.UnitID
			where UnitReductionReasonID in (32,37,41,43,42,44,45,46)
				OR DATEDIFF(D,dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID),ur.ReductionDate) <= 60
			)res60 on res60.ConventionID = c.ConventionID

		--where t.ConventionNo = '1253213'
		)v

	ORDER BY IdTypeRapport
			,ConventionNo



	--SET ARITHABORT OFF

END
