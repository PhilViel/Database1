/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_conf_aju_ind
Nom du service		: Générer la lettre de confirmation de d'ajout de cotisation sur un plan individuel
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_conf_aju_ind @idDemandeCot = 100044
						EXEC psCONV_RapportLettre_le_conf_aju_ind @dtDateCreationDe = '2014-04-01', @dtDateCreationA = '2014-05-02', @iReimprimer = 1
Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2018-05-01		Martin Cyr							Création du service	
		2018-11-08		Maxime Martel						Utilisation de planDesc_ENU de la table plan
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_conf_aju_ind]
    @idDemandeCot INT = NULL,
    @dtDateCreationDe DATETIME = NULL,
    @dtDateCreationA DATETIME = NULL,
    @LangID VARCHAR(3) = NULL,
    @iReimprimer INT = 1
AS
BEGIN

    DECLARE @tCot TABLE (IDDemande INT)

    IF @idDemandeCot IS NOT NULL
        INSERT INTO @tCot VALUES (@idDemandeCot)

    IF @dtDateCreationDe IS NOT NULL AND @dtDateCreationA IS NOT NULL
        INSERT INTO @tCot
        SELECT DISTINCT
            DHD.IDDemande
        FROM DemandeHistoriqueDocument AS DHD
        JOIN DemandeCOT AS DC ON DHD.IDDemande = DC.ID
        JOIN Mo_Human AS h ON DC.IdSouscripteur = h.HumanID
        WHERE DHD.CodeTypeDocument = 'le_conf_aju_ind'
            AND LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10) BETWEEN @dtDateCreationDe AND @dtDateCreationA
            AND ((DHD.EstEmis = 0 AND @iReimprimer = 0)
                    OR (DHD.EstEmis <> 0 AND @iReimprimer <> 0))
            AND (h.LangID = @LangID OR @LangID IS NULL)
        
    DELETE TC
    FROM DemandeHistoriqueDocument DHD
    JOIN DemandeCOT DC ON DHD.IDDemande = DC.Id
    JOIN @tCot TC ON TC.IDDemande = DHD.IDDemande
    JOIN Un_Subscriber S ON S.SubscriberID = DC.IdSouscripteur
    WHERE S.AddressLost = 1

	-- Si on est par plage de date et que ce n'est pas une réimpression, on met EstEmis = 1
    IF @dtDateCreationDe IS NOT NULL AND @dtDateCreationA IS NOT NULL AND ISNULL(@iReimprimer, 0) = 0
            UPDATE DHD
            SET DHD.EstEmis = 1
            FROM DemandeHistoriqueDocument DHD
            JOIN DemandeCOT DC ON DHD.IDDemande = DC.ID
            JOIN dbo.Mo_Human h ON h.HumanID = DC.IdSouscripteur
            JOIN Un_Subscriber S ON S.SubscriberID = DC.IdSouscripteur AND S.AddressLost = 0
            WHERE DHD.CodeTypeDocument = 'le_conf_aju_ind'
                AND DHD.EstEmis = 0
                AND LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10) BETWEEN @dtDateCreationDe AND @dtDateCreationA
                AND (h.LangID = @LangID OR @LangID IS NULL)

    SELECT DISTINCT
        C.ConventionNo,
        LangID = HS.LangID,
        C.SubscriberID,
        PrenomSousc = HS.FirstName,
        NomSousc = HS.LastName,
        AdresseSousc = A.Address,
        CitySousc = A.City,
        ZipCodeSousc = dbo.fn_Mo_FormatZIP(A.ZipCode, A.CountryID),
        StateNameSousc = A.StateName,
        CountrySousc = A.CountryID,
        AppelLongSousc = Sex.LongSexName,
        AppelCourtSousc = Sex.ShortSexName,
        C.BeneficiaryID,
        PrenomBenef = hb.FirstName,
        NomBenef = HB.LastName,
        SexBenef = HB.SexID,
        PlanDesc = CASE WHEN HS.LangID = 'ENU' THEN p.PlanDesc_ENU
                        ELSE P.PlanDesc
                   END,
        C.PlanID,
        Montant = dbo.fn_Mo_MoneyToStr(DC.Montant, HS.LangID, 1),
        Frais = dbo.fn_Mo_MoneyToStr(DC.Frais, HS.LangID, 1),
        P.OrderOfPlanInReport
    FROM Un_Convention C
    JOIN Un_Subscriber Su ON Su.SubscriberID = C.SubscriberID
    JOIN Mo_Human HS ON HS.HumanID = Su.SubscriberID
    JOIN Mo_Human HB ON HB.HumanID = C.BeneficiaryID
    JOIN Mo_Sex Sex ON Sex.SexID = HS.SexID AND Sex.LangID = HS.LangID
    JOIN Mo_Adr A ON HS.AdrID = A.AdrID
    JOIN Mo_Adr Ab ON hb.AdrID = Ab.AdrID
    JOIN Mo_Sex SexB ON SexB.SexID = HB.SexID AND SexB.LangID = HB.LangID
    JOIN DemandeCot DC ON DC.idConvention = C.ConventionID AND DC.idSouscripteur = Su.SubscriberID
    JOIN Un_Plan P ON P.PlanID = C.PlanID
    JOIN @tCot TC ON TC.IDDemande = DC.Id
    ORDER BY
        P.OrderOfPlanInReport,
        NomSousc,
        PrenomSousc

END