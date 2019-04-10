/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas Inc.
Nom                 :	RP_UN_DailyOperRINPayment
Description         :	Rapport des opérations journalières (Décaissement RIN)
Valeurs de retours  :	Dataset de données
				Dataset :
				ConventionNo	VARCHR(20)	Numéro de la convention
				SubscriberName	VARCHAR(75)	Nom et prénom du souscripteur (Ex Caron, Dany)
				dtEmission		DATETIME	Date d’émission du chèque sur l’opération
				iCheckNumber	INTEGER		Numéro du chèque
				Cotisation		MONEY		Montant d’épargne de l’opération
				Fee				MONEY		Montant de frais de l’opération
				fTotal			MONEY		Montant total. Somme de toutes les colonnes. 

Note                :	ADX0001326	IA	2007-04-30	Alain Quirion		Création
										2010-06-10	Donald Huppé		Ajout des régime et groupe de régime
										2014-08-26	Donald Huppé		glpi 12179 : Ajout du nouveau destinaire de chèque (authorisé ou non), concaténé au nom du souscripteur
										2014-09-30	Donald Huppé		glpi 12448 : Ajout du Id DDD et Date décaissement dans l'info du chèque
										2014-10-23	Donald Huppé		glpi 12711 : ajout qté de type de paiement dans totaux par régime
										2014-10-27	Donald Huppé		Si une DDD existe (peu importe son statut, on met idDDD = 0 afin que ça ne sorte pas dans le groupe ND
										2014-11-04	Donald Huppé		glpi 12792 : exclure les DDD 'Refusée','Rejetée','Annulée', 
																		et prendre le max (DDD.id) pour être certain d'en avoir un seul
										2014-11-06	Donald Huppé		glpi 12797 : changer appel de fntOPER_ObtenirEtatDDD
										2015-11-03	Donald Huppé		Enlever le insert dans un_trace	 
										2016-06-17	Donald Huppé		Ajout du paramètre @IncluTousLesEtatsDDD
										2016-08-10	Donald Huppé		JIRA TI-3253 : Séparer no chq et no DDD en 2 colonnes
                                        2017-02-27  Maxime Martel       TI-7023 : Ajout de la cohorte dans le rapport
exec RP_UN_DailyOperRINPayment 1, '2016-06-01','2016-12-31','ALL'

********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_DailyOperRINPayment] (
	@ConnectID	INTEGER,		--	ID de connexion
	@StartDate	DATETIME,		--	Date de début du rapport
	@EndDate	DATETIME,		--	Date de fin du rapport	
	@ConventionStateID	VARCHAR(4), --	Filtre du rapport (‘ALL’ = tous, ‘REEE’ = en RÉÉÉ, ‘TRA’ = transitoire)
	@IncluTousLesEtatsDDD BIT = 0
	)

AS
BEGIN
	--DECLARE
	--	@dtBegin DATETIME,
	--	@dtEnd DATETIME,
	--	@siTraceReport SMALLINT

	--SET @dtBegin = GETDATE()

	CREATE TABLE #tOperTable(
		OperID INT PRIMARY KEY)

	INSERT INTO #tOperTable(OperID)
		SELECT 
			OperID
		FROM Un_Oper
		WHERE OperDate BETWEEN @StartDate AND @EndDate
				  AND OperTypeID = 'RIN'

	IF @ConventionStateID = 'ALL'
		SELECT     
			V.OperDate,
			C.ConventionNo,
			SubscriberName = isnull(CASE
						WHEN H.IsCompany = 0 THEN RTRIM(H.LastName) + ', ' + RTRIM(H.FirstName)
						ELSE RTRIM(H.LastName)
					END ,'')
					+ case when dc.OperID is not null then ' ->' + upper(isnull(hd.FirstName,'') + ' ' + isnull(hd.LastName,'')) else '' end,	
			dtEmission = case 
						when CH.dtEmission is not NULL then CH.dtEmission
						when ddd.DateDecaissement is not NULL then ddd.DateDecaissement
						else NULL
						end,
			iCheckNumber = CH.iCheckNumber,
			--iCheckNumber = case 
			--			when CH.iCheckNumber IS NOT NULL then CH.iCheckNumber
			--			when ddd.id IS NOT NULL then -1 * ddd.id -- multiplier par -1 pour distinguer des numéros de chèque
			--			END,
			DDDNumber = -1 * ddd.id,
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,
			Cotisation = SUM(V.Cotisation),
			Fee = SUM(V.Fee),			
	        Cohorte = C.YearQualif,
			Total = SUM(V.Cotisation) + SUM(V.Fee)
			,TypePmt = case 
					when CH.iCheckNumber IS NOT NULL then 'Chèque'
					when ddd.id IS NOT NULL then 'DDD'
					Else 'ND'
					END
		FROM ( 
				SELECT
					O.OperID,
					U.ConventionID,
					O.OperDate,					

					Co.Cotisation,
					Co.Fee					
				FROM Un_Cotisation CO
				JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID) V
		JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID	
		JOIN UN_PLAN P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		-- Va chercher les informations des chèques
		LEFT JOIN Un_OperLinkToCHQOperation L ON L.OperID = V.OperID
		LEFT JOIN (
					SELECT iCheckID = MAX(CH.iCheckID), OD.iOperationID
					FROM CHQ_OperationDetail OD
					JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID		
					JOIN CHQ_Check CH ON CH.iCheckID = COD.iCheckID					
					GROUP BY OD.iOperationID) R ON R.iOperationID = L.iOperationID
		LEFT JOIN CHQ_Check CH ON CH.iCheckID = R.iCheckID AND CH.iCheckStatusID IN (1,2,4)

		left join (
			select o.OperID, p.iPayeeID
			from un_oper o
			join (
				select o.OperID, co.iOperationID,iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				JOIN #tOperTable OT ON OT.OperID = o.OperID
				join Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				join CHQ_Operation co on co.iOperationID = ol.iOperationID
				join CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				--and o.OperID = 25403991
				group by o.OperID, co.iOperationID
				) v on o.OperID = v.OperID
			join CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
				  
			) dc on dc.OperID = v.OperID and dc.iPayeeID <> h.HumanID
		left JOIN dbo.Mo_Human hd on dc.iPayeeID = hd.HumanID

		left join (
			select 
				ddd2.Id
				,ddd2.IdOperationFinanciere
				,ddd2.DateDecaissement
			from (
				select
					ddd.IdOperationFinanciere
					,id =max(ddd.id) 
				from DecaissementDepotDirect ddd
				join DBO.fntOPER_ObtenirEtatDDD (NULL, @EndDate) t on ddd.Id = t.id
				join un_oper o on ddd.IdOperationFinanciere = o.OperID
				where 
					(@IncluTousLesEtatsDDD = 0 and t.Etat not in ('Refusée','Rejetée','Annulée'))
					or @IncluTousLesEtatsDDD = 1
				group by ddd.IdOperationFinanciere
				) tt
			join DecaissementDepotDirect ddd2 on tt.id = ddd2.Id
			)ddd ON v.OperID = ddd.IdOperationFinanciere

		GROUP BY 
			V.OperDate, 			
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,
			CH.dtEmission,
			Ch.iCheckNumber,
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport
			,dc.OperID,hd.LastName,hd.FirstName
			,ddd.DateDecaissement,ddd.Id, C.YearQualif
		HAVING SUM(V.Cotisation) <> 0
			OR SUM(V.Fee) <> 0
		ORDER BY 
			V.OperDate,  
			H.LastName, 
			H.FirstName,
			C.ConventionNo

	ELSE IF @ConventionStateID = 'REEE'
		SELECT     
			V.OperDate,
			C.ConventionNo,
			SubscriberName = isnull(CASE
						WHEN H.IsCompany = 0 THEN RTRIM(H.LastName) + ', ' + RTRIM(H.FirstName)
						ELSE RTRIM(H.LastName)
					END ,'')
					+ case when dc.OperID is not null then ' ->' + upper(isnull(hd.FirstName,'') + ' ' + isnull(hd.LastName,'')) else '' end,		
			dtEmission = case 
						when CH.dtEmission is not NULL then CH.dtEmission
						when ddd.DateDecaissement is not NULL then ddd.DateDecaissement
						else NULL
						end,
			iCheckNumber = CH.iCheckNumber,
			--iCheckNumber = case 
			--			when CH.iCheckNumber IS NOT NULL then CH.iCheckNumber
			--			when ddd.id IS NOT NULL then -1 * ddd.id -- multiplier par -1 pour distinguer des numéros de chèque
			--			END,
			DDDNumber = -1 * ddd.id,
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,
			Cotisation = SUM(V.Cotisation),
			Fee = SUM(V.Fee),
	        Cohorte = C.YearQualif,
			Total = SUM(V.Cotisation) + SUM(V.Fee)
			,TypePmt = case 
					when CH.iCheckNumber IS NOT NULL then 'Chèque'
					when ddd.id IS NOT NULL then 'DDD'
					Else 'ND'
					END
		FROM ( 
				SELECT
					O.OperID,
					U.ConventionID,
					O.OperDate,

					Co.Cotisation,
					Co.Fee					
				FROM Un_Cotisation CO
				JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID
				WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1))) OR (ISNULL(C.dtRegStartDate, @EndDate+1) < '2003-01-01'))) V		
		JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
		JOIN UN_PLAN P ON P.PlanID = C.PlanID -- select * from UN_PLAN
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime --select * from tblCONV_RegroupementsRegimes
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		-- Va chercher les informations des chèques
		LEFT JOIN Un_OperLinkToCHQOperation L ON L.OperID = V.OperID
		LEFT JOIN (
					SELECT iCheckID = MAX(CH.iCheckID), OD.iOperationID
					FROM CHQ_OperationDetail OD
					JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID		
					JOIN CHQ_Check CH ON CH.iCheckID = COD.iCheckID					
					GROUP BY OD.iOperationID) R ON R.iOperationID = L.iOperationID
		LEFT JOIN CHQ_Check CH ON CH.iCheckID = R.iCheckID AND CH.iCheckStatusID IN (1,2,4)

		left join (
			select o.OperID, p.iPayeeID
			from un_oper o
			join (
				select o.OperID, co.iOperationID,iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				JOIN #tOperTable OT ON OT.OperID = o.OperID
				join Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				join CHQ_Operation co on co.iOperationID = ol.iOperationID
				join CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				--and o.OperID = 25403991
				group by o.OperID, co.iOperationID
				) v on o.OperID = v.OperID
			join CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
				  
			) dc on dc.OperID = v.OperID and dc.iPayeeID <> h.HumanID
		left JOIN dbo.Mo_Human hd on dc.iPayeeID = hd.HumanID

		left join (
			select 
				ddd2.Id
				,ddd2.IdOperationFinanciere
				,ddd2.DateDecaissement
			from (
				select
					ddd.IdOperationFinanciere
					,id =max(ddd.id) 
				from DecaissementDepotDirect ddd
				join DBO.fntOPER_ObtenirEtatDDD (NULL, @EndDate) t on ddd.Id = t.id
				join un_oper o on ddd.IdOperationFinanciere = o.OperID
				where 
					(@IncluTousLesEtatsDDD = 0 and t.Etat not in ('Refusée','Rejetée','Annulée'))
					or @IncluTousLesEtatsDDD = 1
				group by ddd.IdOperationFinanciere
				) tt
			join DecaissementDepotDirect ddd2 on tt.id = ddd2.Id
			)ddd ON v.OperID = ddd.IdOperationFinanciere

		GROUP BY 
			V.OperDate,			
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,
			CH.dtEmission,
			CH.iCheckNumber,
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport
			,dc.OperID,hd.LastName,hd.FirstName
			,ddd.DateDecaissement,ddd.Id, C.YearQualif
		HAVING SUM(V.Cotisation) <> 0
			OR SUM(V.Fee) <> 0			
		ORDER BY 
			V.OperDate, 	
			H.LastName, 
			H.FirstName,
			C.ConventionNo
	ELSE
		SELECT     
			V.OperDate,
			C.ConventionNo,
			SubscriberName = isnull(CASE
						WHEN H.IsCompany = 0 THEN RTRIM(H.LastName) + ', ' + RTRIM(H.FirstName)
						ELSE RTRIM(H.LastName)
					END ,'')
					+ case when dc.OperID is not null then ' ->' + upper(isnull(hd.FirstName,'') + ' ' + isnull(hd.LastName,'')) else '' end,				
			dtEmission = case 
						when CH.dtEmission is not NULL then CH.dtEmission
						when ddd.DateDecaissement is not NULL then ddd.DateDecaissement
						else NULL
						end,
			iCheckNumber = CH.iCheckNumber,
			--iCheckNumber = case 
			--			when CH.iCheckNumber IS NOT NULL then CH.iCheckNumber
			--			when ddd.id IS NOT NULL then -1 * ddd.id -- multiplier par -1 pour distinguer des numéros de chèque
			--			END,
			DDDNumber = -1 * ddd.id,
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,
			Cotisation = SUM(V.Cotisation),
			Fee = SUM(V.Fee),
            Cohorte = C.YearQualif,
			Total = SUM(V.Cotisation) + SUM(V.Fee)
			,TypePmt = case 
					when CH.iCheckNumber IS NOT NULL then 'Chèque'
					when ddd.id IS NOT NULL then 'DDD'
					Else 'ND'
					END
		FROM ( 
				SELECT
					O.OperID,
					U.ConventionID,
					O.OperDate,
					
					Co.Cotisation,
					Co.Fee
				FROM Un_Cotisation CO
				JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID
				WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1)) AND ISNULL(C.dtRegStartDate, @EndDate+1) >= '2003-01-01')) V
		JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
		JOIN UN_PLAN P ON P.PlanID = C.PlanID -- select * from UN_PLAN
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime --select * from tblCONV_RegroupementsRegimes
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		-- Va chercher les informations des chèques
		LEFT JOIN Un_OperLinkToCHQOperation L ON L.OperID = V.OperID
		LEFT JOIN (
					SELECT iCheckID = MAX(CH.iCheckID), OD.iOperationID
					FROM CHQ_OperationDetail OD
					JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID		
					JOIN CHQ_Check CH ON CH.iCheckID = COD.iCheckID					
					GROUP BY OD.iOperationID) R ON R.iOperationID = L.iOperationID
		LEFT JOIN CHQ_Check CH ON CH.iCheckID = R.iCheckID AND CH.iCheckStatusID IN (1,2,4)

		left join (
			select o.OperID, p.iPayeeID
			from un_oper o
			join (
				select o.OperID, co.iOperationID,iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				JOIN #tOperTable OT ON OT.OperID = o.OperID
				join Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				join CHQ_Operation co on co.iOperationID = ol.iOperationID
				join CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				--and o.OperID = 25403991
				group by o.OperID, co.iOperationID
				) v on o.OperID = v.OperID
			join CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
				  
			) dc on dc.OperID = v.OperID and dc.iPayeeID <> h.HumanID
		left JOIN dbo.Mo_Human hd on dc.iPayeeID = hd.HumanID

		left join (
			select 
				ddd2.Id
				,ddd2.IdOperationFinanciere
				,ddd2.DateDecaissement
			from (
				select
					ddd.IdOperationFinanciere
					,id =max(ddd.id) 
				from DecaissementDepotDirect ddd
				join DBO.fntOPER_ObtenirEtatDDD (NULL, @EndDate) t on ddd.Id = t.id
				join un_oper o on ddd.IdOperationFinanciere = o.OperID
				where 
					(@IncluTousLesEtatsDDD = 0 and t.Etat not in ('Refusée','Rejetée','Annulée'))
					or @IncluTousLesEtatsDDD = 1
				group by ddd.IdOperationFinanciere
				) tt
			join DecaissementDepotDirect ddd2 on tt.id = ddd2.Id
			)ddd ON v.OperID = ddd.IdOperationFinanciere

		GROUP BY 
			V.OperDate,			
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,		
			CH.dtEmission,
			Ch.iCheckNumber,
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport
			,dc.OperID,hd.LastName,hd.FirstName
			,ddd.DateDecaissement,ddd.Id, C.YearQualif
		HAVING SUM(V.Cotisation) <> 0
			OR SUM(V.Fee) <> 0			
		ORDER BY 
			V.OperDate, 	
			H.LastName, 
			H.FirstName,
			C.ConventionNo

	--DROP TABLE #tOperTable


	/*
	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
	BEGIN
		-- Insère un log de l'objet inséré.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				2,				
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Rapport journalier des opérations (Décaissement RIN) entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_DailyOperRINPayment',
				'EXECUTE RP_UN_DailyOperRINPayment @ConnectID ='+CAST(@ConnectID AS VARCHAR)+				
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)+	
				', @ConventionStateID ='+@ConventionStateID				
	END	
	*/
END


