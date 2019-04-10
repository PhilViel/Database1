/********************************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc
Nom                 :	fntREPR_ObtenirUniteConvT
Description         :	Obtenir les groupe D'unité des convention T avec FRS à 11.50 avec le RepID du souscriteur actif lors de la vente ainsi que le directeur
						sera utilisé dans le rapport d'unité brutes et nettes afin que la vente sorte sous ce rep et non sous le rep "Siège Social" qui est associé au groupe d'unité
						
						Et les conventions I de BEC seulement

						Pour retrouver le rep du souscripteur lors de la vente (inforceDate), on utilise l'historique dans les tables tblCONV_ChangementsRepresentants%
						C'est géré comme ça depuis quelques années, mais de tout façon, ce projet débute en 2016, en prenant les ventes de 2016 et plus alors on est ok

Valeurs de retours  :	Dataset de données

Note                :	
					2016-10-28	Donald Huppé	Création 	

SELECT * FROM fntREPR_ObtenirUniteConvT (1) WHERE dtFirstDeposit BETWEEN '2016-01-01' AND '2016-11-13'
SELECT * FROM fntREPR_ObtenirUniteConvT (1) WHERE dtFirstDeposit BETWEEN '2016-01-01' AND '2016-10-28'
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntREPR_ObtenirUniteConvT] 
					(	
					@bValiderDateDebut BIT --= 1
					)
RETURNS @tUnitRep 
	TABLE (
			UnitID INT
			,RepID INT
			,BossID INT
			,dtFirstDeposit DATETIME
		  )
BEGIN

	DECLARE @DateDebut DATETIME = '2016-01-01'

	DECLARE @HistRepSousc TABLE
	(
        iID_Souscripteur INT,
		iID_ChangementRepresentant INT,
        OldRepID INT,
        NewRepID INT,
        dDate_Statut DATETIME
	)

	DECLARE @SouscREP table
	(
        iID_Souscripteur INT,
		RepID INT,
        StartDate DATETIME,
		EndDate DATETIME
	)


	DECLARE @DateEncaissBEC table
	(
        ConventionID INT,
        DateEncaissBEC DATETIME
	)
	
	-- Voir psCONV_RapportChangementRepresentants
	INSERT INTO @HistRepSousc
    SELECT
        CRCS.iID_Souscripteur,
		CR.iID_ChangementRepresentant,
        OldRepID = CRCS.iID_RepresentantOriginal,
        NewRepID = CRC.iID_RepresentantCible,
        CR.dDate_Statut
	--into #HistRepSousc
    FROM tblCONV_ChangementsRepresentants CR
    JOIN tblCONV_ChangementsRepresentantsCibles CRC ON cr.iID_ChangementRepresentant = CRC.iID_ChangementRepresentant
    JOIN tblCONV_ChangementsRepresentantsCiblesSouscripteurs CRCS ON CRC.iID_ChangementRepresentantCible = CRCS.iID_ChangementRepresentantCible
	join Un_Convention c on crcs.iID_Souscripteur = c.SubscriberID 
    WHERE 
		ISNULL(CRCS.iID_RepresentantOriginal, '') <> ''
        AND ISNULL(crc.iID_RepresentantCible, '') <> ''
		-- AND dbo.FN_CRQ_DateNoTime(CR.dDate_Statut) BETWEEN '2010-01-01' AND '2016-12-31'
        AND CR.iID_Statut = 3 -- Exécuté
		AND ( c.ConventionNo like 'T%' OR C.ConventionNo LIKE 'I%')



	INSERT INTO @SouscREP

	select *
	from (
		-- Le plus vieux rep avant le début des changement
		select 
			HR.iID_Souscripteur
			,RepID = OldRepID
			,StartDate = '1900-01-01'
			,EndDate = HR.dDate_Statut
		from @HistRepSousc HR
		join (
			select iID_Souscripteur, dDate_Statut = min(dDate_Statut) 
			from @HistRepSousc 
			group by iID_Souscripteur
			) hr1 on hr.iID_Souscripteur = hr1.iID_Souscripteur and hr.dDate_Statut = hr1.dDate_Statut

		UNION ALL

		-- Les changement de rep
		select
			iID_Souscripteur
			,RepID = NewRepID
			,StartDate
			, EndDate = isnull(min(EndDate),'9999-12-31')
		from (	
			select
				aDebut.NewRepID,aDebut.iID_Souscripteur,StartDate = aDebut.dDate_Statut, EndDate = aFin.dDate_Statut
			from 
				@HistRepSousc aDebut
				left join @HistRepSousc aFin on 
									aDebut.iID_Souscripteur = afin.iID_Souscripteur 
								and aFin.dDate_Statut >= aDebut.dDate_Statut  
								and aFin.iID_ChangementRepresentant > aDebut.iID_ChangementRepresentant
			) V

		group BY
			iID_Souscripteur
			,NewRepID
			,StartDate

		UNION ALL

		-- Les souscripteur qui n'ont pas eu de changement de rep
		select DISTINCT
			iID_Souscripteur = s.SubscriberID
			,RepID = s.RepID
			,StartDate = '1900-01-01'
			,EndDate = '9999-12-31'
		from Un_Subscriber s
		join Un_Convention c on s.SubscriberID = c.SubscriberID 
		left join @HistRepSousc hr on s.SubscriberID = hr.iID_Souscripteur
		where hr.iID_Souscripteur is null
		AND (c.ConventionNo like 'T%' OR C.ConventionNo LIKE 'I%')

		)T

	order by iID_Souscripteur,StartDate


	INSERT INTO @DateEncaissBEC 
	SELECT CE2.ConventionID, DateEncaissBEC = MIN(O2.OperDate)
	FROM Un_Convention C2
	JOIN Un_Plan P2 ON C2.PlanID = P2.PlanID
	JOIN UN_CESP CE2 ON CE2.ConventionID = C2.ConventionID
	JOIN UN_OPER O2 ON CE2.OperID = O2.OperID
	LEFT JOIN Un_OperCancelation OC12 ON O2.OperID = OC12.OperSourceID
	LEFT JOIN Un_OperCancelation OC22 ON O2.OperID = OC22.OperID
	WHERE 
		C2.ConventionNo LIKE 'I-%'
		AND o2.OperDate >= @DateDebut
		AND	P2.PlanTypeID = 'IND'
		AND CE2.fCLB > 0
		AND OC12.OperSourceID IS NULL
		AND OC22.OperID IS NULL
	GROUP BY CE2.ConventionID




	INSERT INTO @tUnitRep 

	SELECT DISTINCT
		u.UnitID
		,sr.RepID
		,BossID
		,U.dtFirstDeposit
	FROM Un_Convention c
	JOIN Un_Subscriber s on s.SubscriberID = c.SubscriberID
	JOIN Un_Unit u on c.ConventionID = u.ConventionID
	JOIN @SouscREP sr on s.SubscriberID = sr.iID_Souscripteur and u.InForceDate BETWEEN sr.StartDate and sr.EndDate
    LEFT JOIN (
		SELECT 
			M.UnitID,
			BossID = MAX(RBH.BossID)
		FROM (
			SELECT 
				U.UnitID,
				SR.RepID,
				RepBossPct = MAX(RBH.RepBossPct)
			FROM Un_Unit U
			JOIN Un_Convention C ON U.ConventionID = C.ConventionID
			JOIN @SouscREP SR ON C.SubscriberID = SR.iID_Souscripteur AND U.InForceDate BETWEEN sr.StartDate and sr.EndDate
			JOIN Un_RepBossHist RBH ON RBH.RepID = SR.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
			JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
			JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
			GROUP BY U.UnitID, SR.RepID
			) M
		JOIN Un_Unit U ON U.UnitID = M.UnitID
		JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
		GROUP BY 
			M.UnitID
		) Boss ON U.UnitID = Boss.UnitID

	join Un_Cotisation ct on u.UnitID = ct.UnitID
	join Un_Oper o on o.OperID = ct.OperID
	left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
	left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
	where 
		c.ConventionNo like 'T%'
		and o.OperTypeID = 'FRS'
		and ct.Cotisation = -11.50
		AND (
				(@bValiderDateDebut = 1 AND u.dtFirstDeposit >= @DateDebut)
			OR	 @bValiderDateDebut = 0 
			)
		and oc1.OperSourceID is NULL -- non annulé
		and oc2.OperID is null -- pas une annulation


	UNION ALL

	SELECT DISTINCT
		u.UnitID
		,sr.RepID
		,BossID
		,dtFirstDeposit = DateEncaissBEC  -- Date de réception du BEC --CS.Date_REE -- On prend la date de passage à l'état REE
	FROM 
		Un_Convention C
		JOIN Un_Subscriber s ON s.SubscriberID = c.SubscriberID
		JOIN Un_Unit U ON C.ConventionID= U.ConventionID
		JOIN @SouscREP sr ON s.SubscriberID = sr.iID_Souscripteur and u.InForceDate BETWEEN sr.StartDate and sr.EndDate
		JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
		JOIN Un_Oper O ON CT.OperID = O.OperID
		--JOIN (
		--	-- Nous préconiserions la date de changement de statut de la convention à « Transitoire » ou « REEE » qui correspond à la date ou la convention est activée par les agents aux opérations.
		--	SELECT 
		--		CCS.ConventionID,
		--		Date_REE = MIN(CCS.StartDate)
		--	FROM Un_ConventionConventionState CCS
		--	WHERE CCS.ConventionStateID IN (/*'TRA',*/ 'REE') 
		--	GROUP BY CCS.ConventionID
		--	) CS ON CS.ConventionID = C.ConventionID

		JOIN @DateEncaissBEC EncaissBEC ON EncaissBEC.ConventionID = C.ConventionID
		LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
		LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
		LEFT JOIN (
			SELECT DISTINCT c.ConventionID
			FROM
				Un_Convention C
				JOIN Un_Unit U ON C.ConventionID= U.ConventionID
				JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
				JOIN Un_Oper O ON CT.OperID = O.OperID
				LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
				LEFT JOIN Mo_BankReturnLink BRL on BRL.BankReturnSourceCodeID = O.OperID
			WHERE 1=1
				AND C.ConventionNo like 'I-%'
				AND O.OperTypeID <> 'BEC'
				AND (ct.Cotisation <> 0 OR ct.Fee <> 0)
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL
				AND BRL.BankReturnSourceCodeID is NULL
				AND u.RepID = 149876
				--AND C.ConventionNo = 'I-20160418002'
		)NOT_BEC ON NOT_BEC.ConventionID = C.ConventionID
		LEFT JOIN (
			SELECT DISTINCT iID_Convention_Destination  
			FROM tblOPER_OperationsRIO
			WHERE OperTypeID = 'TRI'
				)TRI ON TRI.iID_Convention_Destination = C.ConventionID
		LEFT JOIN (
			SELECT 
				M.UnitID,
				BossID = MAX(RBH.BossID)
			FROM (
				SELECT 
					U.UnitID,
					SR.RepID,
					RepBossPct = MAX(RBH.RepBossPct)
				FROM Un_Unit U
				JOIN Un_Convention C ON U.ConventionID = C.ConventionID
				JOIN @SouscREP SR ON C.SubscriberID = SR.iID_Souscripteur AND U.InForceDate BETWEEN sr.StartDate and sr.EndDate
				JOIN Un_RepBossHist RBH ON RBH.RepID = SR.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
				JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
				JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
				GROUP BY U.UnitID, SR.RepID
				) M
			JOIN Un_Unit U ON U.UnitID = M.UnitID
			JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
			GROUP BY 
				M.UnitID
			) Boss ON U.UnitID = Boss.UnitID
	WHERE 
		C.ConventionNo LIKE 'I-%'
		AND o.OperTypeID = 'BEC'
		AND (
				(@bValiderDateDebut = 1 AND DateEncaissBEC >= @DateDebut)
			OR	 @bValiderDateDebut = 0 
			)
		AND OC1.OperSourceID IS NULL
		AND OC2.OperID IS NULL
		AND u.RepID = 149876 -- SIÈGE SOCIAL
		AND NOT_BEC.ConventionID IS NULL --
		AND TRI.iID_Convention_Destination IS NULL -- EXCLUT LES CONVENTIONS ISSU D'UN TRI


	ORDER BY u.UnitID

	RETURN 

END

