/****************************************************************************************************
Code de service		:		psCONV_ObtenirListeConventionsResiliee
Nom du service		:		Obtenir la liste des conventions résiliées
But					:		Obtenir la liste des conventions résiliées
							
Facette				:		?
Reférence			:		?

Parametres d'entrée :	Parametres					Description                                 Obligatoire
                        ----------                  ----------------                            --------------   
                        iConnectID					ConnectID									On le met au cas où on voudrait s'en servir plus tard. mettre 1                    
                        dtStartDate				    La date de début	                        Oui
						dtEndDate		            La date de fin						        Oui
						iRepID						Id du Représentant							Oui.  Mettre 0 pour tous les représentants

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                    
Historique des modifications :
			
						Date					Programmeur							Description							Référence
						----------			---------------------------------	----------------------------		---------------
						2010-01-18		Donald Huppé							Création de la procédure
						2010-03-23		Donald Huppé							ajout de la colonne "FraisCouvert"
						2014-09-12		Pierre-Luc Simard					    Récupérer uniquement le dernier profil souscripteur
                        2017-02-22      Pierre-Luc Simard                       Retirer PEE de la validation pour les cotisations
                        2017-08-29      Pierre-Luc Simard                       Ajout des RDI
						2018-09-07		Maxime Martel							JIRA MP-699 Ajout de OpertypeID COU

exec psCONV_ObtenirListeConventionsResiliee 1, '2010-01-01','2010-03-10',0 -- 149471

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirListeConventionsResiliee] (	
	@iConnectID INTEGER, --
	@dtStartDate DATETIME, -- date de début pour la recherche
	@dtEndDate DATETIME, -- date de fin pour la recherche
	@iRepID INTEGER = 0) -- ID du représentant, 0 pour ne pas appliquer ce critère
AS

BEGIN

	CREATE TABLE #TB_Rep (RepID int) -- Création table temporaire pour recherche par représentant

	-- Insère tous les représentants sous un rep dans la table temporaire
	INSERT #TB_Rep
		EXEC SL_UN_BossOfRep @iRepID

	CREATE TABLE #tRESUnit(
		UnitID INTEGER PRIMARY KEY,
		ConventionID INTEGER,
		TerminatedDate DATETIME)

	INSERT INTO #tRESUnit
		SELECT 
			U.UnitID,
			U.ConventionID,
			U.TerminatedDate
		FROM dbo.Un_Convention C  (Readuncommitted)
		JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
		LEFT JOIN (
				SELECT ConventionID 
				FROM dbo.Un_Unit (Readuncommitted)
				WHERE ISNULL(TerminatedDate,0) < 1
			) TR ON TR.ConventionID = C.ConventionID
		WHERE TR.ConventionID IS NULL
			AND U.TerminatedDate >= @dtStartDate
			AND U.TerminatedDate < @dtEndDate + 1

	CREATE TABLE #tRESConvention(
		ConventionID INTEGER PRIMARY KEY,
		DatePRD	DATETIME,
		TerminatedDate DATETIME,
		MaxUnitID INTEGER)

	INSERT INTO #tRESConvention
		SELECT 
			U.ConventionID,
			DatePRD = min(U.dtFirstDeposit),
			TerminatedDate = MAX(RU.TerminatedDate),
			MaxUnitID = MAX(U.UnitID)
		FROM 
			#tRESUnit RU
			JOIN dbo.Un_Unit U  (Readuncommitted) ON U.ConventionID = RU.ConventionID
		GROUP BY 
			U.ConventionID

	CREATE TABLE #tUnitReduction(
		UnitID INTEGER PRIMARY KEY,
		UnitQty MONEY,
		UnitReductionID INTEGER,
		UnitReductionReasonID INTEGER)

	INSERT INTO #tUnitReduction
		SELECT 
			R.UnitID,
			R.UnitQty,
			R.UnitReductionID,
			R.UnitReductionReasonID
		FROM (-- Retrouve la plus récente réduction par groupe d'unité
			SELECT 
				RU.UnitID, 
				UnitReductionID = MAX(UnitReductionID) 
			FROM #tRESUnit RU
			JOIN Un_UnitReduction  (Readuncommitted) UR ON RU.UnitID = UR.UnitID
			GROUP BY RU.UnitID
			) T
		JOIN Un_UnitReduction R ON T.UnitReductionID = R.UnitReductionID

	-- montant du dépôt du groupe d'unité avant la dernière réduction
	CREATE TABLE #tUnitDepot(
		UnitID INTEGER PRIMARY KEY,
		Depot MONEY)

	insert into #tUnitDepot
	select
		U.UnitID,
		Depot = ROUND(M.PmtRate * (U.UnitQty+ isnull(UR.UnitQty,0)),2) + -- Cotisation et frais
				dbo.FN_CRQ_TaxRounding
					((	CASE U.WantSubscriberInsurance -- Assurance souscripteur
							WHEN 0 THEN 0
						ELSE ROUND(M.SubscriberInsuranceRate * (U.UnitQty + isnull(UR.UnitQty,0)),2)
						END +
						ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
					(1+ISNULL(St.StateTaxPct,0))) -- Taxes
	FROM dbo.Un_Unit U (Readuncommitted) 
	JOIN #tRESUnit T on U.UnitID = T.UnitID
	left JOIN #tUnitReduction UR on UR.unitid = u.unitID
	JOIN Un_Modal M  (Readuncommitted) ON U.ModalID = M.ModalID
	JOIN dbo.Un_Convention C  (Readuncommitted) ON C.ConventionID = U.ConventionID
	JOIN dbo.Un_Subscriber S  (Readuncommitted) ON S.SubscriberID = C.SubscriberID
	LEFT JOIN Mo_State St  (Readuncommitted) ON St.StateID = S.StateID
	LEFT JOIN Un_BenefInsur BI  (Readuncommitted) ON BI.BenefInsurID = U.BenefInsurID

	CREATE TABLE #tSumCotisationFee(
		UnitID INTEGER PRIMARY KEY,
		Cotisation MONEY,
		Fee MONEY)

	INSERT INTO #tSumCotisationFee-- Sommarise les frais et les cotisations par groupe d'unités
		SELECT  
			UnitID = RU.UnitID,  
			Cotisation = SUM(C.Cotisation),  
			Fee = SUM(C.Fee) 
		FROM #tRESUnit RU
		JOIN Un_Cotisation C  (Readuncommitted) ON C.UnitID = RU.UnitID
		JOIN Un_Oper O  (Readuncommitted) ON O.OperID = C.OperID
		WHERE O.OperTypeID IN ('RES', 'OUT', 'TRA') -- certains types d'opération -- PLS 2017-02-22
		GROUP BY RU.UnitID 

	CREATE TABLE #tConventionState(
		ConventionID INTEGER PRIMARY KEY,
		ConventionStateName VARCHAR(75))

	INSERT INTO #tConventionState
		SELECT 
			T.ConventionID,
			CS.ConventionStateName
		FROM (-- Retourne la plus grande date de début d'un état par convention
			SELECT 
				RC.ConventionID,
				MaxDate = MAX(CCS.StartDate)
			FROM #tRESConvention RC
			JOIN Un_ConventionConventionState CCS  (Readuncommitted) ON RC.ConventionID = CCS.ConventionID
			WHERE CCS.StartDate <= GETDATE() -- État actif
			GROUP BY RC.ConventionID
			) T
		JOIN Un_ConventionConventionState CCS  (Readuncommitted) ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
		JOIN Un_ConventionState CS  (Readuncommitted) ON CCS.ConventionStateID = CS.ConventionStateID -- Pour retrouver la description de l'état
		
	-- Retourne les conventions terminées
	SELECT   
		C.ConventionID,  
		C.ConventionNo,  
		C.SubscriberID,  
		SubscriberName = 
			CASE 
				WHEN H.IsCompany = 1 THEN H.LastName
			ELSE H.LastName + ', ' + H.FirstName
			END,
		NbUnitsBeforeReduction = SUM(U.UnitQty + ISNULL(UR.UnitQty,0)),  
		Depot = ISNULL(SUM(UD.Depot),9999990),
		Cotisation = ISNULL(SUM(T.Cotisation),0),  
		Fee = ISNULL(SUM(T.Fee),0),
		DureeContrat = DATEDIFF(MM,RC.DatePRD, RC.terminatedDate),
		TerminatedReason = MIN(URR.UnitReductionReason),
		--ConventionState = MIN(CS.ConventionStateName),
		DepassBareme = CASE 
						WHEN PS.iID_Depassement_Bareme = 0 THEN 'Non' 
						WHEN PS.iID_Depassement_Bareme is NULL THEN 'NA' 
						ELSE 'Oui'
						END,
		Justifications = CASE WHEN PS.iID_Depassement_Bareme = 1 THEN PS.vcDepassementBaremeJustification ELSE '' END,
		Rep = HR.FirstName + ' ' + HR.LastName,
		Directeur = HB.FirstName + ' ' + HB.LastName,
		FraisCouvert = case when ftp.FeeToPay <= isnull(cf.FeePaid,0) then 'oui' else 'non' end,
		ftp.FeeToPay,
		CF.FeePaid
	--into #tmpdonald
	FROM #tRESConvention RC
	JOIN dbo.Un_Convention C  (Readuncommitted) ON C.ConventionID = RC.ConventionID
	JOIN dbo.Un_Subscriber S  (Readuncommitted) ON C.SubscriberID = S.SubscriberID
	join (	
			select 
				u.conventionid,
				FeeToPay = sum(ur.unitqty * m.feebyunit)
			from 
				un_unitreduction  ur
				JOIN dbo.Un_Unit u on u.unitid = ur.unitid
				join un_modal m on u.modalid = m.modalid -- select * from un_modal
			group by u.conventionid
		)ftp on C.ConventionID = ftp.ConventionID
	LEFT JOIN (-- Retourne la somme des frais disponibles par convention
			/*
			SELECT
				CO.ConventionID,
				AvailableFeeAmount = SUM(CO.ConventionOperAmount)
			FROM Un_ConventionOper CO
			JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
			WHERE CO.ConventionOperTypeID = 'FDI'
			  --AND C.conventionno = '2061295'
			GROUP BY CO.ConventionID				
			*/
			select 
				u1.conventionid,
				FeePaid = sum(ct1.fee)
			from un_cotisation ct1
			JOIN dbo.Un_Unit u1 on ct1.unitid = u1.unitid
			join un_oper op1 on ct1.operid = op1.operid
			where 
				(op1.opertypeid in ('CPA','NSF','AJU','CHQ','PRD','RCB','FCB','TIN','RDI','COU')
				or
				(ct1.fee>0 and op1.opertypeid = 'TFR'))
			group by u1.conventionid	
			
			) CF ON CF.ConventionID = C.ConventionID
	LEFT JOIN tblCONV_ProfilSouscripteur PS ON PS.iID_Souscripteur = S.SubscriberID AND PS.DateProfilInvestisseur = (
		SELECT	
			MAX(PSM.DateProfilInvestisseur)
		FROM tblCONV_ProfilSouscripteur PSM
		WHERE PSM.iID_Souscripteur = PS.iID_Souscripteur
			AND PSM.DateProfilInvestisseur <= GETDATE()
		)
	JOIN dbo.Un_Unit  (Readuncommitted) U ON U.ConventionID = C.ConventionID
	LEFT JOIN #tUnitDepot UD ON U.UnitID = UD.UnitID
	LEFT JOIN dbo.Un_Unit URep  (Readuncommitted) on RC.MaxUnitID = URep.UnitID -- Les Rep du dernier unit de la convention
	left JOIN dbo.Mo_Human HR  (Readuncommitted) on HR.HumanID = URep.RepID
	LEFT JOIN #TB_Rep B ON B.RepID = URep.RepID -- table temporaire, vide si aucun critère sur le directeur/représentant
	LEFT JOIN (
		SELECT
			RB.RepID,
			BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
		FROM 
			Un_RepBossHist RB
			JOIN (
				SELECT
					RepID,
					RepBossPct = MAX(RepBossPct)
				FROM 
					Un_RepBossHist RB (Readuncommitted) 
				WHERE 
					RepRoleID = 'DIR'
					AND StartDate IS NOT NULL
					AND (StartDate <= GETDATE())
					AND (EndDate IS NULL OR EndDate >= GETDATE())
				GROUP BY
					  RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		  WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate IS NOT NULL
				AND (RB.StartDate <= GETDATE())
				AND (RB.EndDate IS NULL OR RB.EndDate >= GETDATE())
		  GROUP BY
				RB.RepID
		) BR on BR.Repid = URep.RepID
	LEFT JOIN dbo.Mo_Human HB  (Readuncommitted) on HB.HumanID = BR.BossID
	LEFT JOIN dbo.Mo_Human H  (Readuncommitted) ON H.HumanID = C.SubscriberID	
	LEFT JOIN #tUnitReduction UR ON U.UnitID = UR.UnitID
	LEFT JOIN Un_UnitReductionReason URR  (Readuncommitted) ON UR.UnitReductionReasonID = URR.UnitReductionReasonID
	LEFT JOIN #tSumCotisationFee T ON U.UnitID = T.UnitID
	LEFT JOIN #tConventionState CS ON C.ConventionID = CS.ConventionID	
	WHERE B.RepID IS NOT NULL OR @iRepID = 0
	GROUP BY 
		C.ConventionID, 
		C.ConventionNo, 
		C.SubscriberID, 
		H.LastName, 
		H.FirstName,
		H.IsCompany,
		RC.DatePRD,
		RC.terminatedDate,
		PS.iID_Depassement_Bareme,
		PS.vcDepassementBaremeJustification,
		HR.FirstName + ' ' + HR.LastName,
		HB.FirstName + ' ' + HB.LastName,
		ftp.FeeToPay,CF.FeePaid
	ORDER BY 
		C.ConventionNo 
		
	DROP TABLE #TB_Rep -- Libère la table temporaire
	DROP TABLE #tRESConvention
	DROP TABLE #tRESUnit
	
END