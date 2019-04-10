
/****************************************************************************************************
Code de service		:		psGENE_RapportOutilGestionChangementAuPlan
Nom du service		:		psGENE_RapportOutilGestionChangementAuPlan
But					:		JIRA TI-5692 : Pour l'outil de gestion de changement au plan
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_RapportOutilGestionChangementAuPlan 623872

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-11-22					Donald Huppé							Création du Service
						2016-11-23					Donald Huppé							correction inversement Frais épargne + nouveau champs
						2016-11-28					Donald Huppé							Ajout de 4 champs
						2016-11-29					Donald Huppé							Ajout 2 champs
						2016-12-13					Donald Huppé							solde EPG en date du jour. SCEE par unité, RENDEMENTS SÉPARÉS
						2017-01-18					Donald Huppé							Ajout de inforceDate
						2017-01-24					Donald Huppé							Ajout de DateRIEstime et DateDernierRI
						2017-02-21					Donald Huppé							Ajout de DateNaissanceSousc
						2017-02-22					Donald Huppé							Ajout de AgeBenefModalite
						2017-11-16					Donald Huppé							jira ti-10081 : Ajout de DateRIOriginale
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportOutilGestionChangementAuPlan] (
	@SUBSCRIBERID INT
	)


AS
BEGIN

--DECLARE @SUBSCRIBERID INT = 575993

		SELECT 
			IdSouscripteur = C.SubscriberID
			,AppellationSouscripteur = SXS.LongSexName
			,NomSouscripteur = HS.LastName
			,PrenomSouscripteur = HS.FirstName
			,AdresseSouscripteur = A.Address
			,VilleSouscripteur = A.City
			,ProvinceSouscripteur = A.StateName
			,CodePostalSouscripteur = dbo.fn_Mo_FormatZIP(A.ZipCode,A.CountryID)
			,NumeroConvention = C.ConventionNo
			,NomPlan = P.PlanDesc
			,NomBenef = HB.LastName
			,PrenomBenef = HB.FirstName
			,IdGroupeUnites = U.UnitID
			,NomRepresentant = HR.FirstName + ' ' + HR.LastName
			,Date1erDepot = CAST( U.dtFirstDeposit AS DATE)
			,DateSignature = CAST( U.SignatureDate AS DATE)
			,DateModalite = CAST( M.ModalDate AS DATE)
			,NombreUnites = U.UnitQty
			,AgeBenef1erDepot = M.BenefAgeOnBegining
			,FrequenceCotisation /*(A, M, U)*/ = 
						CASE
						WHEN m.PmtQty = 1 THEN 'U'
						WHEN m.PmtByYearID = 12 THEN 'M'
						WHEN m.PmtQty > 1 and m.PmtByYearID = 1 THEN 'A'
						END
			,QuantitePaiements = M.PmtQty
			,MontantCotisation = CAST(ROUND( U.UnitQty * M.PmtRate,2) AS MONEY)
			,MontantAssurance = CAST(
									CASE U.WantSubscriberInsurance -- Assurance souscripteur
										WHEN 0 THEN 0
										ELSE ROUND(M.SubscriberInsuranceRate * (U.UnitQty),2)
									END 
									+ ISNULL(BI.BenefInsurRate,0)
									AS MONEY )
			,FraisCumulatif = ISNULL(SoldeFrais,0)
			,FraisCumulatifEstime = EstimatedFee
			,EpargneCumulatif = ISNULL(SoldeEpargne ,0)
			,EpargneCumulatifEstime = EstimatedCotisationAndFee - EstimatedFee

			,DateDernierDepotPrevu = CAST(ESTM.LastDepositDate AS DATE)
			,DateDernierDepotReleveContrat = CAST(u.LastDepositForDoc AS DATE)

			,SCEECumulatif = isnull(SoldeSCEE,0)
			,SCEEPlusCumulatif = isnull(SoldeSCEEPlus,0)
			,IQEECumulatif = isnull(SoldeIQEE,0)
			,IQEEPlusCumulatif = isnull(SoldeIQEEPlus,0)
			,BEC = isnull(SoldeBEC,0)
			,RevenuSurEpargne = ISNULL(RevenuSurEpargne,0)
			,RevenuSurSCEE = ISNULL(RevenuSurSCEE,0)
			,RevenuSurSCEEPlus = ISNULL(RevenuSurSCEEPlus,0)
			,RevenuSurIQEE = ISNULL(RevenuSurIQEE,0)
			,RevenuSurIQEEPlus = ISNULL(RevenuSurIQEEPlus,0)
			,InteretSCEE_TIN = ISNULL(InteretSCEE_TIN,0)
			,InteretIQEE_TIN = ISNULL(InteretIQEE_TIN,0)
			,DateNaissanceBenef = CAST(hb.BirthDate AS DATE)
			,PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1)

			,SoldeSCEEUnite = ISNULL(SoldeSCEEUnite,0)
			,SoldeSCEEPlusUnite = ISNULL(SoldeSCEEPlusUnite,0)

			,INC = ISNULL(INC,0)
			,RendRI_INM = ISNULL(RendRI_INM,0)
			,RendTIN_ITR = ISNULL(RendTIN_ITR,0)
			,MIM = ISNULL(MIM,0)
			,ICQ = ISNULL(ICQ,0)
			,IIQ = ISNULL(IIQ,0)
			,IMQ = ISNULL(IMQ,0)
			,III = ISNULL(III,0)
			,IQI = ISNULL(IQI,0)
			,DateDebutOperFin = cast( u.inforceDate as date)
			,DateRIEstime
			,DateDernierRI = cast(u.IntReimbDate as DATE)
			,DateNaissanceSousc = CAST(hs.BirthDate AS DATE)
			,AgeBenefModalite = m.BenefAgeOnBegining
			,DateRIOriginale

		from Un_Convention C
		joiN UN_PLAN P ON P.PlanID = C.PlanID
		JOIN Un_Subscriber S ON c.SubscriberID = S.SubscriberID
		JOIN Mo_Human HS on hs.HumanID = s.SubscriberID
		JOIN MO_ADR A ON HS.AdrID = A.AdrID
		JOIN Mo_Sex SXS on SXS.SexID = HS.SexID AND SXS.LangID = HS.LangID
		JOIN Mo_Human HB ON HB.HumanID = C.BeneficiaryID
		JOIN Mo_Human HR ON HR.HumanID = S.RepID
		JOIN Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Modal M ON U.ModalID = M.ModalID
		LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
		LEFT JOIN (
			SELECT U.UnitID
				,SoldeEpargne = sum(ct.Cotisation)
				,SoldeFrais = sum(ct.Fee)
			FROM Un_Unit U
			JOIN Un_Convention C ON U.ConventionID= C.ConventionID
			JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
			JOIN Un_Oper O ON O.OperID = CT.OperID
			WHERE C.SubscriberID = @SUBSCRIBERID
				AND O.OperDate <= CAST(GETDATE() AS DATE)
			GROUP BY U.UnitID
			)COTIS ON COTIS.UnitID = U.UnitID

		LEFT JOIN (
			SELECT DISTINCT
				c.ConventionID,
				U.UnitID,
				EstimatedCotisationAndFee = dbo.FN_UN_EstimatedCotisationAndFee(U.InForceDate,GETDATE(),DAY(c.FirstPmtDate),u.UnitQty,m.PmtRate,m.PmtByYearID,m.PmtQty,u.InForceDate) ,
				EstimatedFee = dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(
																	U.InForceDate, 
																	GETDATE(), 
																	DAY(C.FirstPmtDate), 
																	U.UnitQty, 
																	M.PmtRate, 
																	M.PmtByYearID, 
																	M.PmtQty, 
																	U.InForceDate), 
														U.UnitQty, 
														M.FeeSplitByUnit, 
														M.FeeByUnit)
				,LastDepositDate = dbo.fn_Un_LastDepositDate(u.InForceDate,c.FirstPmtDate,m.PmtQty,m.PmtByYearID)
				,DateRIEstime = cast(dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust) as DATE)
				,DateRIOriginale = cast(dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, NULL) as DATE)
			FROM Un_Convention c
			JOIN Un_Unit u ON c.ConventionID = u.ConventionID
			JOIN Un_Modal m ON u.ModalID = m.ModalID
			JOIN Un_Plan p ON c.PlanID = p.PlanID
			WHERE C.SubscriberID = @SUBSCRIBERID
			)ESTM ON ESTM.UnitID = U.UnitID

		LEFT JOIN (
			SELECT --select * from un_conventionopertype
				c.ConventionID
				,SoldeIQEE = SUM( CASE WHEN co.ConventionOperTypeID = 'CBQ' THEN co.ConventionOperAmount ELSE 0 END)
				,SoldeIQEEPlus = SUM( CASE WHEN co.ConventionOperTypeID = 'MMQ' THEN co.ConventionOperAmount ELSE 0 END)

				,RevenuSurEpargne = SUM( CASE WHEN co.ConventionOperTypeID in ('INM','ITR') THEN co.ConventionOperAmount ELSE 0 END)
				,RevenuSurSCEE = SUM( CASE WHEN co.ConventionOperTypeID in ('INS') THEN co.ConventionOperAmount ELSE 0 END)
				,RevenuSurSCEEPlus = SUM( CASE WHEN co.ConventionOperTypeID in ('IS+') THEN co.ConventionOperAmount ELSE 0 END)
				,RevenuSurIQEE =  SUM( CASE WHEN co.ConventionOperTypeID in ('ICQ','III','IIQ','MIM') THEN co.ConventionOperAmount ELSE 0 END) --= (isnull(oper.IQEEBase,0) + isnull(oper.ICQ,0) +isnull(oper.III,0) + isnull(oper.IIQ,0) + isnull(oper.MIM,0) + isnull(oper.IQI,0)),
				,RevenuSurIQEEPlus =  SUM( CASE WHEN co.ConventionOperTypeID in ('IMQ') THEN co.ConventionOperAmount ELSE 0 END)
				,InteretSCEE_TIN = SUM( CASE WHEN co.ConventionOperTypeID in ('IST') THEN co.ConventionOperAmount ELSE 0 END)
				,InteretIQEE_TIN = SUM( CASE WHEN co.ConventionOperTypeID in ('IQI') THEN co.ConventionOperAmount ELSE 0 END)
				,INC = SUM( CASE WHEN co.ConventionOperTypeID in ('INC') THEN co.ConventionOperAmount ELSE 0 END)
				,RendRI_INM = SUM( CASE WHEN co.ConventionOperTypeID in ('INM') THEN co.ConventionOperAmount ELSE 0 END)
				,RendTIN_ITR = SUM( CASE WHEN co.ConventionOperTypeID in ('ITR') THEN co.ConventionOperAmount ELSE 0 END)
				,MIM = SUM( CASE WHEN co.ConventionOperTypeID in ('MIM') THEN co.ConventionOperAmount ELSE 0 END)
				,ICQ = SUM( CASE WHEN co.ConventionOperTypeID in ('ICQ') THEN co.ConventionOperAmount ELSE 0 END)
				,IIQ = SUM( CASE WHEN co.ConventionOperTypeID in ('IIQ') THEN co.ConventionOperAmount ELSE 0 END)
				,IMQ = SUM( CASE WHEN co.ConventionOperTypeID in ('IMQ') THEN co.ConventionOperAmount ELSE 0 END)
				,III = SUM( CASE WHEN co.ConventionOperTypeID in ('III') THEN co.ConventionOperAmount ELSE 0 END)
				,IQI = SUM( CASE WHEN co.ConventionOperTypeID in ('IQI') THEN co.ConventionOperAmount ELSE 0 END)
			FROM Un_ConventiON c
			JOIN Un_ConventionOper co ON co.ConventionID = c.ConventionID
			JOIN Un_Oper o ON co.OperID = o.OperID
			WHERE C.SubscriberID = @SUBSCRIBERID
				and co.ConventionOperTypeID in ( 'CBQ','MMQ','IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','MIM','IQI','ITR')
			GROUP by 
				c.BeneficiaryID
				,c.ConventionID
			)IQEE ON IQEE.ConventionID = C.ConventionID

		LEFT JOIN (
			SELECT 
				c.ConventionID,
				SoldeSCEE = SUM(CE.fCESG),
				SoldeSCEEPlus = SUM(CE.fACESG),
				SoldeBEC = SUM(CE.fCLB)
			FROM Un_ConventiON c
			JOIN Un_CESP CE ON CE.ConventionID = c.ConventionID
			WHERE 
				C.SubscriberID = @SUBSCRIBERID
			GROUP BY 
				c.ConventionID
			)SCEE ON SCEE.ConventionID = C.ConventionID

		LEFT JOIN (
			SELECT 
				U1.UnitID,
				SoldeSCEEUnite = SUM(CE1.fCESG),
				SoldeSCEEPlusUnite = SUM(CE1.fACESG)
			FROM Un_Unit U1
			JOIN Un_Convention C1 ON U1.ConventionID = C1.ConventionID
			JOIN Un_Cotisation Ct1 ON Ct1.UnitID = U1.UnitID 
			JOIN Un_CESP CE1 ON (CE1.CotisationID = Ct1.CotisationID  and CE1.ConventionID = U1.ConventionID)
			JOIN Un_Oper OP1 ON OP1.OperID = CE1.OperID 
			WHERE C1.SubscriberID = @SUBSCRIBERID
			GROUP BY U1.UnitID

			)SCEE_UNITE ON SCEE_UNITE.UnitID = U.UnitID


		WHERE C.SubscriberID = @SUBSCRIBERID

END