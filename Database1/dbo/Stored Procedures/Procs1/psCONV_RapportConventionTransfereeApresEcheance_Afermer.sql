/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: psCONV_RapportConventionTransfereeApresEcheance_Afermer
Nom du service		: psCONV_RapportConventionTransfereeApresEcheance_Afermer
But 				: jira PROD-5841 - Pour France Ménard
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportConventionTransfereeApresEcheance_Afermer
						
Paramètres de sortie:	

Historique des modifications:
    Date			Programmeur							Description
    ------------	----------------------------------	----------------------------------------------------
    2017-06-29		Donald Huppé						Création du service
    2017-07-20      Pierre-Luc Simard                   Ajout du conventionID			
    2017-07-26      Steeve Picard                       Ajout du paramètre @EndDate lors de l'appel
	2018-05-30		Donald Huppé						Ajustement de la validation de l'admissibilité et des PAE payés
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportConventionTransfereeApresEcheance_Afermer] --des conventions transférées après échéance à fermer
(
    @EndDate DATETIME = NULL
)
AS 
BEGIN
    IF @EndDate IS NULL
        SET @EndDate = GETDATE()
/*


Requête pour les conventions collectives à l'état REEE qui sont:
 -admissible aux bourses ou 
-bourse 1 payée ou 
-bourse 1 et 2 payée 
-la dernière transaction est un TIO vers une convention T 
-il y a un arrêt de paiement sur la convention collective.

Le solde des comptes de cotisations, SCEE, SCEE +, BEC, IQEE et IQEE + doivent être à 0 $

Il faut retrouver:
-numéro de convention
 -ID du souscripteur

exemple de cas:
 1199143
 D-20010509001
 1232274

*/

	if object_id('tempdb..#MaxOutOper') IS NOT NULL drop table #MaxOutOper
	if object_id('tempdb..#MaxOper') IS NOT NULL drop table #MaxOper


		SELECT ConventionID,conventionno, OUTOperID = MAX( v10.OperID)
		INTO #MaxOutOper
		FROM (

			SELECT DISTINCT c.ConventionID, c.ConventionNo, o.OperID
			FROM Un_Convention C
			JOIN Un_ConventionOper co ON Co.ConventionID= c.ConventionID
			JOIN Un_Oper O ON Co.OperID = O.OperID
			JOIN un_tio tio ON tio.iOUTOperID = o.OperID
			JOIN Un_Oper otin ON otin.OperID = tio.iTINOperID
			JOIN Un_ConventionOper cotin ON cotin.OperID = otin.OperID
			JOIN Un_Convention ctin	 ON ctin.ConventionID = cotin.ConventionID
			LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
			LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
			WHERE 1=1
				AND o.OperTypeID = 'OUT'
				AND c.PlanID <> 4
				AND ctin.ConventionNo like 'T%'
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL


			UNION ALL

			SELECT DISTINCT c.ConventionID, c.ConventionNo,  o.OperID
			FROM Un_Convention C
			JOIN Un_CESP ce ON Ce.ConventionID= c.ConventionID
			JOIN Un_Oper O ON Ce.OperID = O.OperID
			JOIN un_tio tio ON tio.iOUTOperID = o.OperID
			JOIN Un_Oper otin ON otin.OperID = tio.iTINOperID
			JOIN Un_CESP cetin ON cetin.OperID = otin.OperID
			JOIN Un_Convention ctin	 ON ctin.ConventionID = cetin.ConventionID
			LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
			LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
			WHERE 1=1
				AND o.OperTypeID = 'OUT'
				AND c.PlanID <> 4
				AND ctin.ConventionNo like 'T%'
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL

			) v10
		GROUP BY ConventionID,conventionno

		SELECT ConventionID, MAXOperID = MAX( v10.OperID)
		INTO #MaxOper
		FROM (

			SELECT DISTINCT c.ConventionID, c.ConventionNo, o.OperID
			FROM Un_Convention C
			JOIN #MaxOutOper ot ON c.ConventionID = ot.ConventionID
			JOIN Un_ConventionOper co ON Co.ConventionID= c.ConventionID
			JOIN Un_Oper O ON Co.OperID = O.OperID
			LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
			LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
			WHERE 1=1
				AND o.OperTypeID not in ('in+','in-','SUB','IQE')
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL

			UNION ALL

			SELECT DISTINCT c.ConventionID, c.ConventionNo,  o.OperID
			FROM Un_Convention C
			JOIN #MaxOutOper ot ON c.ConventionID = ot.ConventionID
			JOIN Un_CESP ce ON Ce.ConventionID= c.ConventionID
			JOIN Un_Oper O ON Ce.OperID = O.OperID
			LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
			LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
			WHERE 1=1
				AND o.OperTypeID not in ('in+','in-','SUB','IQE')
				AND OC1.OperSourceID IS NULL
				AND OC2.OperID IS NULL

			) v10
		GROUP BY ConventionID



		SELECT DISTINCT
			conv.ConventionNo, 
            conv.ConventionID,
			CONV.SubscriberID,
			NomSousc = hs.LastName,
			PrenomSousc = hs.FirstName,
			AppelLong = SEX.LongSexName,
			AppelCourt = SEX.ShortSexName,
			Langue = hs.LangID,
			Adresse = adr.Address,
			Ville = adr.City,
			Province = adr.StateName,
			CodePostal = dbo.fn_Mo_FormatZIP(adr.ZipCode,adr.CountryID),
			PrenomBenef = Hb.FirstName,
			DateSignature,
			ConventionStateID,
			DateDernierTIO = cast(Otio.operDate as date)
		
	
		FROM Un_Convention conv
		JOIN Mo_Human hs ON hs.HumanID = conv.SubscriberID
		JOIN MO_SEX SEX ON SEX.LangID = HS.LangID AND SEX.SexID = HS.SexID
		JOIN mo_adr adr ON adr.AdrID = hs.AdrID
		JOIN Mo_Human Hb ON HB.HumanID = conv.BeneficiaryID
		JOIN (
			SELECT u.ConventionID, DateSignature = CAST(MIN(u.SignatureDate) as DATE)
			FROM Un_Unit u
			GROUP BY u.ConventionID
			)DtSign ON DtSign.ConventionID = conv.ConventionID
		JOIN (
			SELECT 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			FROM 
				un_conventionconventionstate cs
				JOIN (
					SELECT 
					conventionid,
					startdate = MAX(startDate)
					FROM un_conventionconventionstate
					WHERE startDate < DATEADD(d,1 ,@EndDate)
					GROUP BY conventionid
					) ccs ON ccs.conventionid = cs.conventionid 
						AND ccs.startdate = cs.startdate 
						AND cs.ConventionStateID <> 'FRM'
			) css ON conv.conventionid = css.conventionid

		JOIN (
			SELECT DISTINCT br.ConventionID FROM Un_Breaking br
			WHERE @EndDate BETWEEN br.BreakingStartDate AND ISNULL(br.BreakingEndDate,'9999-12-31')
			)arret ON arret.ConventionID = conv.ConventionID

		JOIN #MaxOutOper MaxOutOper ON MaxOutOper.ConventionID = conv.ConventionID

		JOIN #MaxOper MaxOper ON MaxOper.ConventionID = conv.ConventionID AND MaxOper.MAXOperID = MaxOutOper.OUTOperID

		LEFT JOIN Un_Oper Otio ON Otio.OperID = MaxOutOper.OUTOperID

		LEFT JOIN (
				SELECT
					U.ConventionID,
					Épargne = SUM(Ct.Cotisation),
					Frais = SUM(Ct.Fee)
				FROM Un_Unit U
				JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
				JOIN un_oper o ON ct.operid = o.operid
				JOIN #MaxOutOper MaxOutOper ON MaxOutOper.ConventionID = u.ConventionID
				WHERE o.operdate <= @EndDate
				GROUP BY U.ConventionID
			) ep ON conv.conventionid = ep.conventionid


		LEFT JOIN (
				SELECT 
					S.ConventionID, 
					mQuantite_UniteDemande =	CASE WHEN TU.TotalUniteConv <= SUM(ISNULL(S.mQuantite_UniteDemande, 0)) 
														THEN TU.TotalUniteConv -- SI ON A DONNE PLUS D'UNTIÉ EN PAE QUE LE NB TOTAL DANS LA CONV ALORS C'EST PAS LOGIQUE MAIS ON RETOURNE TotalUniteConv
												ELSE SUM(ISNULL(S.mQuantite_UniteDemande, 0)) 
												END
					-- ratio d'unité demandé en PAE en date du
					,RatioDemande =		CASE WHEN TU.TotalUniteConv > 0 THEN
										(
												CASE WHEN TU.TotalUniteConv <= SUM(ISNULL(S.mQuantite_UniteDemande, 0)) 
														THEN TU.TotalUniteConv -- SI ON A DONNE PLUS D'UNTIÉ EN PAE QUE LE NB TOTAL DANS LA CONV ALORS C'EST PAS LOGIQUE MAIS ON RETOURNE TotalUniteConv
												ELSE SUM(ISNULL(S.mQuantite_UniteDemande, 0)) 
												END
										) / TU.TotalUniteConv * 1.0
										ELSE 0 END
				FROM 
					Un_Scholarship S
					JOIN (
						SELECT U2.ConventionID, TotalUniteConv = sum(UnitQty)
						from Un_Unit u2
						group by U2.ConventionID
						)TU	 on TU.ConventionID = S.ConventionID
					JOIN (
						SELECT S1.ScholarshipID, MAXOperDate = MAX(O1.OperDate)
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
					--AND MAXOperDate <= @dtDateTo -- comme la valeur de quotee part est en date du jour, alors on prend tous les PAE en date du jour, et non en date de fin
				GROUP BY S.ConventionID,TU.TotalUniteConv

		)PAE ON PAE.ConventionID = CONV.ConventionID


		--LEFT JOIN (
		--		SELECT
		--			c2.ConventionID
		--		FROM un_convention c2
		--		JOIN Un_Scholarship s ON c2.ConventionID = s.ConventionID
		--		JOIN #MaxOutOper MaxOutOper ON MaxOutOper.ConventionID = c2.ConventionID
		--		WHERE 1=1
		--			AND s.ScholarshipNo = 1
		--			AND s.ScholarshipStatusID in ('ADM','PAD')
		--		GROUP BY c2.ConventionID
		--	) pae ON conv.conventionid = pae.conventionid

		LEFT JOIN dbo.fntCONV_ObtenirConventionAdmissiblePAE (NULL) RBA ON RBA.ConventionID = CONV.ConventionID

		--LEFT JOIN (
		--	SELECT distinct u.conventionid
		--	FROM un_unit u
		--	JOIN (
		--		SELECT 
		--			us.unitid,
		--			uus.startdate,
		--			us.UnitStateID
		--		FROM 
		--			Un_UnitunitState us
		--			JOIN (
		--				SELECT 
		--				unitid,
		--				startdate = MAX(startDate)
		--				FROM un_unitunitstate
		--				--WHERE startDate < DATEADD(d,1 ,'2014-02-08')
		--				GROUP BY unitid
		--				) uus ON uus.unitid = us.unitid 
		--					AND uus.startdate = us.startdate 
		--					AND us.UnitStateID in ('RBA')
		--		)uus ON uus.unitID = u.UnitID
		--	) RBA ON rba.conventionid = conv.conventionid

		LEFT JOIN (
			SELECT 
				ce.conventionid,
				SCEE = SUM(fcesg),
				SCEEPlus = SUM(facesg),
				BEC = SUM(fCLB)
			FROM un_cesp ce
			JOIN un_oper op ON ce.operid = op.operid
			JOIN #MaxOutOper MaxOutOper ON MaxOutOper.ConventionID = ce.ConventionID
			WHERE op.operdate <= @EndDate
			GROUP BY ce.conventionid
			) scee ON conv.conventionid = scee.conventionid
		
		LEFT JOIN (
			SELECT
				c.conventionid,
				IQEEBase = SUM(CASE WHEN ot.conventionopertypeid = 'CBQ' THEN ConventionOperAmount ELSE 0 END ),
				IQEEMajore = SUM(CASE WHEN ot.conventionopertypeid = 'MMQ' THEN ConventionOperAmount ELSE 0 END )
			FROM 
				un_conventionoper co
				JOIN un_oper o ON co.operid = o.operid
				JOIN un_conventionopertype ot ON co.conventionopertypeid = ot.conventionopertypeid
				JOIN un_convention c ON co.conventionid = c.conventionid
				JOIN #MaxOutOper MaxOutOper ON MaxOutOper.ConventionID = c.ConventionID
			
			WHERE 
				o.operdate <= @EndDate
				AND ot.conventionopertypeid in( 'CBQ','MMQ')

			GROUP BY c.conventionid
				) oper ON conv.ConventionID = oper.ConventionID

		WHERE 1=1
			--AND conv.conventionno = '1199143'
			AND (
				ISNULL(pae.RatioDemande,0) > 0 AND ISNULL(pae.RatioDemande,0) < 1
				or 
				rba.conventionid IS NOT NULL
				)
			AND (
				ISNULL(SCEE.SCEE,0) = 0
				AND ISNULL(SCEE.SCEEPlus,0) = 0
				AND ISNULL(SCEE.BEC,0) = 0
				AND ISNULL(oper.IQEEBase,0) = 0
				AND ISNULL(oper.IQEEMajore,0) = 0

				AND ISNULL(Épargne,0) = 0
				AND ISNULL(Frais,0) = 0 

				)

		ORDER BY conv.conventionno


	--SELECT * FROM un_conventionopertype

END


