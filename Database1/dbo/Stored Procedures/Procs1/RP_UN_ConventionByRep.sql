/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : RP_UN_ConventionByRep
Description         : Procédure stockée du rapport : Détail des souscripteurs du représentant
Valeurs de retours  : >0  :	Tout à fonctionné
                      <=0 :	Erreur SQL
								-1	: Erreur lors de la sauvegarde de l'ajout
								-2 : Cette année de qualification est déjà en vigueur pour cette convention
Note                :						    2004-05-12	Dominic Létourneau	Création de la procedure pour CRQ-INT-00003
								ADX0000309	BR	2004-06-03 	Bruno Lapointe		Correction
								ADX0000631	IA	2005-01-03	Bruno Lapointe		Ajout du paramètre @SubscriberIDs pour filtre
								                                            	supplémentaire.
								ADX0001285	BR	2005-02-15	Bruno Lapointe		Optimisation.
												2008-12-10  Patrick Robitaille  Afficher Oui/Non au lieu des NAS s'ils sont valides ou non
																				et ajouter les adresses de courriel
												2009-08-13	Donald Huppé	    Inscrire "*** adresse perdue ***" dans adresse, tel et email du souscripteur et bébéficiaire si AddressLost = 1
												2010-10-15	Donald Huppé	    Ajout d'un champ "Actif" indiquant si le sousc est actif,
																			    Modification de la clause where pour sortir aussi les données de sousc inactif quand on passe une liste de subscriberID
												2011-09-29	Donald Huppé	    GLPI 6141 : Remplacer phone1 par Mobile, lorsque NULL. Remplacer phone2 par OtherTel lorsque NULL.
												2012-10-30	Donald Huppé	    Dans le calcul du MntSouscrit, dans le case : WHEN PmtEndConnectID IS not NULL THEN (SommeFee + SommeCotisation)

																			    On vérifie que PmtEndConnectID "IS not NULL" au lieu de "IS NULL"
												2013-08-07  Maxime Martel	    ajout de l'option "tous" pour les directeurs des agences
												2013-09-23	Donald Huppé	    glpi 20214 : ajout de SubscriberID et BeneficiaryID
												2015-01-19	Donald Huppé	    ajouter des join sur la table #TB_Rep pour améliorer la vitesse
												2016-08-09	Donald Huppé	    JIRA TI-4216 : Ajout de DateDernierDepot, et tous les téléphone 
                                                2017-06-22  Pierre-Luc Simard   JIRA REM-783: Ajout de la validation avec le représentant sur l'épargne pour le champ Transfert 
                                                                                Retrait du paramètre @SubscriberIDs qui n'est plus utilisé (Laissé pour Delphi)
                                                2018-02-06  Pierre-Luc Simard   Optimisation
												2018-06-28	Donald Huppé		Modification pour afficher seulement les souscripteurs du directeur adjoint
                                                2018-09-26  Pierre-Luc Simard   Ajout de l'audit dans la table tblGENE_AuditHumain

exec RP_UN_ConventionByRep 1, 655109, '', null --121071
exec RP_UN_ConventionByRep 1, 149602, '', null
exec RP_UN_ConventionByRep2 1, 0, '308239'
exec RP_UN_ConventionByRep2 1, 0, '399934'
exec RP_UN_ConventionByRep2 1, 0, '', 2
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ConventionByRep] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepID INTEGER = 0, -- Limiter les résultats selon un représentant, 0 pour tous
	@SubscriberIDs VARCHAR(8000),-- IDs de souscripteur du représentant à afficher séparés par des virgules. '' = tous
	@userID integer = null) 
AS
BEGIN

    DECLARE 
        @Rep BIT = 0,
        @NbRep INT = 0,
		@EstDirecteurAdjoint int = 0
	
    CREATE TABLE #tb_rep (
        RepID INTEGER PRIMARY KEY)
	
    IF @UserID IS NOT NULL
        BEGIN
		    -- Insère tous les représentants sous un rep dans la table temporaire			
            SELECT
                @Rep = COUNT(DISTINCT RepID)
            FROM Un_Rep
            WHERE @UserID = RepID
	
            IF @rep = 1
                BEGIN
                    INSERT #tb_rep
                    EXEC SL_UN_BossOfRep @UserID
                END
            ELSE
                BEGIN
                    INSERT #tb_rep
                    SELECT RepID                        
                    FROM Un_Rep
                END

            IF @RepID <> 0
                BEGIN
                    DELETE #tb_rep
                    WHERE RepID <> @RepID
                END
        END
    ELSE
        BEGIN
            IF @RepID <> 0
                BEGIN
                    INSERT INTO #tb_rep
                    EXEC SL_UN_BossOfRep @RepID
                END
            ELSE
                BEGIN
                    INSERT INTO #tb_rep
                    SELECT RepID
                    FROM Un_Rep
                END
        END

	-- 2018-06-28 : La définition d'un directeur adjoint est ceci selon ce qu'on trouve dans la bd : si son pct de DIR est entre 0 et 20 alors c'est un directeur adjoint
	-- Et on veut juste sortir ses souscripteurs à lui
	SELECT 
		@EstDirecteurAdjoint = BossID
	FROM Un_RepBossHist bh
	JOIN Un_Rep	r on r.RepID = bh.RepID
	JOIN Mo_Human h on h.HumanID = bh.BossID
	WHERE 1=1
		AND BossID = @RepID
		AND ISNULL(r.BusinessEnd,'9999-12-31') > getdate()
		AND ISNULL(EndDate, getdate() + 1) > getdate()
		AND RepRoleID IN ('DIR', 'DIS', 'PRO', 'PRS')
	GROUP BY BossID
	HAVING MAX(RepBossPct) BETWEEN 0.001 and 20	


	IF @EstDirecteurAdjoint > 0
		BEGIN
		DELETE FROM #tb_rep WHERE RepID <> @RepID
		END
	-----------------------------------------------------------------------------------------------

    SELECT @NbRep = COUNT(*)
    FROM #tb_rep

    ;WITH CTE_Unit AS (
        SELECT
            U.ConventionID,
            C.ConventionNo,
            C.PlanID,
            C.SubscriberID,
            C.BeneficiaryID,
            P.PlanDesc,
            P.PlanTypeID,
            U.SignatureDate,
            U.InForceDate,
            U.RepID,
            SRepID = S.RepID,
            U.PmtEndConnectID,
            M.PmtQty,
            M.PmtByYearID,
            U.UnitQty,
            M.PmtRate,
            StateTaxPct = ISNULL(St.StateTaxPct, 0),
            SommeFee = ISNULL(SUM(CT.Fee), 0),
            SommeCotisation = ISNULL(SUM(CT.Cotisation), 0),
            SubscrInsur = CASE WHEN U.WantSubscriberInsurance = 0 THEN 0 ELSE ROUND(U.UnitQty * M.SubscriberInsuranceRate, 2) END,
            BenefInsur = ISNULL(BI.BenefInsurRate, 0),
            DateDernierDepot = ISNULL(U.LastDepositForDoc, dbo.fn_Un_LastDepositDate(U.InForceDate, C.FirstPmtDate, M.PmtQty, M.PmtByYearID)),
            U.iID_RepComActif
        FROM dbo.Un_Unit U
        JOIN Un_Modal M ON U.ModalID = M.ModalID
        LEFT JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
        JOIN Un_Plan P ON M.PlanID = P.PlanID
        JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
        JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
        JOIN #tb_rep r ON S.RepID = r.repID
        LEFT JOIN Mo_State St ON St.StateID = S.StateID
        LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
        WHERE U.TerminatedDate IS NULL
        GROUP BY
            U.ConventionID,
            C.ConventionNo,
            C.PlanID,
            P.PlanDesc,
            C.SubscriberID,
            C.BeneficiaryID,
            U.UnitID,
            U.SignatureDate,
            U.InForceDate,
            U.RepID,
            U.PmtEndConnectID,
            U.WantSubscriberInsurance,
            U.UnitQty,
            M.PmtQty,
            M.PmtByYearID,
            M.PmtRate,
            M.SubscriberInsuranceRate,
            P.PlanTypeID,
            St.StateTaxPct,
            S.RepID,
            BI.BenefInsurRate,
            C.FirstPmtDate,
            U.LastDepositForDoc,
            U.iID_RepComActif
        ),
        CTE_Conv AS (
        SELECT
            UN.ConventionID,
            UN.ConventionNo,
            UN.PlanID,
            UN.PlanDesc,
            UN.SubscriberID,
            UN.BeneficiaryID,
            MntSouscrit = SUM(CASE WHEN PlanTypeID = 'IND' THEN SommeCotisation
                                   WHEN PmtEndConnectID IS NOT NULL
                                   THEN (SommeFee + SommeCotisation)
                                   WHEN PmtQty = 1
                                   THEN (SommeFee + SommeCotisation)
                                   ELSE (PmtQty * ROUND((UnitQty * PmtRate), 2))
                              END),
            Transfert = MAX(CASE WHEN (UN.RepID <> UN.SRepID) OR (UN.iID_RepComActif <> UN.SRepID) THEN 1 ELSE 0 END),
            DSignature = MIN(SignatureDate),
            Dvigueur = MAX(InForceDate),
            Nb_Unit = SUM(UnitQty),
            Nb_Paiement = MAX(PmtQty),
            MntDepot = SUM(CASE WHEN PlanTypeID = 'IND' THEN SommeCotisation
                                WHEN PmtQty = 1
                                     AND (PmtEndConnectID IS NULL)
                                THEN (SommeFee + SommeCotisation)
                                ELSE ROUND(UnitQty * PmtRate, 2) + dbo.FN_CRQ_TaxRounding((SubscrInsur + BenefInsur) * (1 + StateTaxPct))
                           END),
            MAXDePmtByYearID = MAX(PmtByYearID),
            DateDernierDepot = MAX(DateDernierDepot)
        FROM CTE_Unit UN
        GROUP BY 
            UN.ConventionID,
            UN.ConventionNo,
            UN.PlanID,
            UN.PlanDesc,
            UN.SubscriberID,
            UN.BeneficiaryID
        ) 
        SELECT 
            NbRep = @NbRep,
            @Rep AS estrep,
            T.ConventionNo,
            T.Transfert,
            T.PlanDesc,
            T.Dvigueur,
            T.DSignature,
            T.Nb_Unit,
            NbPaiementAns = T.MAXDePmtByYearID,
            T.Nb_Paiement,
            T.MntSouscrit,
            T.MntDepot,
            SLastName = HS.LastName,
            SFirstName = HS.FirstName,
            SAddress = CASE WHEN S.AddressLost = 0 THEN SAdr.Address ELSE '*** adresse perdue ***' END,
            SCity = CASE WHEN S.AddressLost = 0 THEN SAdr.City ELSE '' END,
            SStateName = CASE WHEN S.AddressLost = 0 THEN SAdr.StateName ELSE '' END,
            SCountryID = CASE WHEN S.AddressLost = 0 THEN SAdr.CountryID ELSE '' END,
            SZipCode = CASE WHEN S.AddressLost = 0 THEN SAdr.ZipCode ELSE '' END,
            SPhone1 = CASE WHEN S.AddressLost = 0 THEN ISNULL(SAdr.Phone1, SAdr.Mobile) ELSE '' END,
            SPhone2 = CASE WHEN S.AddressLost = 0 THEN ISNULL(SAdr.Phone2, SAdr.OtherTel) ELSE '' END,
            SSexID = HS.SexID,
            SLangName = CASE SLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(SLang.LangName, 'Unknown') END,
            SBirthDate = HS.BirthDate,    
            SSocialNumber = CASE WHEN dbo.FN_CRI_CheckSin(ISNULL(HS.SocialNumber, HS.IsCompany), 0) = 1 THEN 'Oui' ELSE 'Non' END,
            SEMail = CASE WHEN S.AddressLost = 0 THEN SAdr.EMail ELSE '' END,
            BLastName = HB.LastName,
            BFirstName = HB.FirstName,
            BAddress = CASE WHEN B.bAddressLost = 0 THEN BAdr.Address ELSE '*** adresse perdue ***' END,
            BCity = CASE WHEN B.bAddressLost = 0 THEN BAdr.City ELSE '' END,
            BStateName = CASE WHEN B.bAddressLost = 0 THEN BAdr.StateName ELSE '' END,
            BCountryID = CASE WHEN B.bAddressLost = 0 THEN BAdr.CountryID ELSE '' END,
            BZipCode = CASE WHEN B.bAddressLost = 0 THEN BAdr.ZipCode ELSE '' END,
            BPhone1 = ISNULL(BAdr.Phone1, ''),
            BPhone2 = ISNULL(BAdr.Phone2, ''),
            BTelMobile = ISNULL(BAdr.Mobile, ''),
            BSexID = HB.SexID,
            BLangName = CASE BLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(BLang.LangName, 'Unknown') END,
            BBirthDate = HB.BirthDate,
            BSocialNumber = CASE WHEN dbo.FN_CRI_CheckSin(ISNULL(HB.SocialNumber, ''), 0) = 1 THEN 'Oui' ELSE 'Non' END,
            BEMail = CASE WHEN B.bAddressLost = 0 THEN BAdr.EMail ELSE '' END,
            r.RepCode,
            RLastName = HR.LastName,
            RFirstName = HR.FirstName,
            r.repID,
            ACTIF = 1,
            S.SubscriberID,
            B.BeneficiaryID,
            DateDernierDepot,
            STelMobile = ISNULL(SAdr.Mobile, ''),
            SOtherTel = ISNULL(SAdr.OtherTel, '')
        INTO #tRP_UN_ConventionByRep
        FROM CTE_Conv T
        JOIN dbo.Un_Subscriber S ON S.SubscriberID = T.SubscriberID 
        JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = T.BeneficiaryID
        JOIN dbo.Mo_Human HS ON HS.HumanID = S.SubscriberID
        JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
        JOIN dbo.Mo_Adr SAdr ON HS.AdrID = SAdr.AdrID
        JOIN dbo.Mo_Adr BAdr ON BAdr.AdrID = HB.AdrID
        JOIN Un_Rep R ON S.RepID = R.repID
        JOIN dbo.Mo_Human HR ON r.repID = HR.HumanID
        LEFT JOIN Mo_Lang SLang ON HS.LangID = SLang.LangID
        LEFT JOIN Mo_Lang BLang ON HB.LangID = BLang.LangID
        ORDER BY
            HR.LastName,
            HR.FirstName,
            HS.LastName,
            HS.FirstName,
            T.ConventionNo

    DROP TABLE #tb_rep

    SELECT * FROM #tRP_UN_ConventionByRep

    ----------------
    -- AUDIT - DÉBUT
    ----------------
    BEGIN 
        DECLARE 
            @vcAudit_Utilisateur VARCHAR(75) = dbo.GetUserContext(),
            @vcAudit_Contexte VARCHAR(75) = OBJECT_NAME(@@PROCID)
    
        -- Ajout de l'audit dans la table tblGENE_AuditHumain
        EXEC psGENE_AuditAcces 
            @vcNom_Table = '#tRP_UN_ConventionByRep', 
            @vcNom_ChampIdentifiant = 'SubscriberID', 
            @vcUtilisateur = @vcAudit_Utilisateur, 
            @vcContexte = @vcAudit_Contexte, 
            @bAcces_Courriel = 1, 
            @bAcces_Telephone = 1, 
            @bAcces_Adresse = 1

        EXEC psGENE_AuditAcces 
            @vcNom_Table = '#tRP_UN_ConventionByRep', 
            @vcNom_ChampIdentifiant = 'BeneficiaryID', 
            @vcUtilisateur = @vcAudit_Utilisateur, 
            @vcContexte = @vcAudit_Contexte, 
            @bAcces_Courriel = 1, 
            @bAcces_Telephone = 1, 
            @bAcces_Adresse = 1
    --------------
    -- AUDIT - FIN
    --------------
    END 
END