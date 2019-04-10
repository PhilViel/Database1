/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_nq_COT
Nom du service		: Générer la lettre de non qualification COT
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_nq_COT @IDDemandeRIN = 203
						EXEC psCONV_RapportLettre_le_nq_COT @dtDateCreationDe = '2014-02-17', @dtDateCreationA = '2014-06-24', @iReimprimer = 0, @LangID = 'ENU'
Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2018-06-05		Sébastien Rodrigue					MP-129
			
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_nq_COT]
    @IDDemande INT = NULL,
    @dtDateCreationDe DATETIME = NULL,
    @dtDateCreationA DATETIME = NULL,
    @LangID VARCHAR(3) = NULL,
    @iReimprimer INT = 0
AS
BEGIN
    DECLARE
        @nbSouscripteur INT,
        @nbConvListe INT,
        @nbConv INT,
        @today DATETIME

    DECLARE @Demande TABLE (IDDemande INT)
	
    SET @today = GETDATE()

    IF @IDDemande IS NOT NULL
        INSERT INTO @Demande VALUES (@IDDemande)

    IF @dtDateCreationDe IS NOT NULL AND @dtDateCreationA IS NOT NULL
        INSERT INTO @Demande
        SELECT IDDemande
        FROM DemandeHistoriqueDocument DHD
        JOIN DemandeCOT DP ON DHD.IDDemande = DP.Id
        JOIN dbo.Mo_Human h ON h.HumanID = DP.IdSouscripteur
        WHERE DHD.CodeTypeDocument = 'le_nq_cot'
            AND LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10) BETWEEN @dtDateCreationDe AND @dtDateCreationA
            AND ((DHD.EstEmis = 0 AND @iReimprimer = 0)
                OR (DHD.EstEmis <> 0 AND @iReimprimer <> 0))
            AND (h.LangID = @LangID OR @LangID IS NULL)

    DELETE TD
    FROM DemandeHistoriqueDocument DHD
    JOIN DemandeCOT DP ON DHD.IDDemande = DP.Id
    JOIN dbo.Mo_Human h ON h.HumanID = DP.IdSouscripteur
    JOIN Un_Subscriber S ON S.SubscriberID = DP.IdSouscripteur
    JOIN @Demande TD ON TD.IDDemande = DHD.IDDemande
    WHERE S.AddressLost = 1

	-- Si on est par plage de date et que ce n'est pas une réimpression, on met EstEmis = 1
    IF @dtDateCreationDe IS NOT NULL AND @dtDateCreationA IS NOT NULL AND @iReimprimer = 0
            UPDATE DHD
            SET DHD.EstEmis = 1
            FROM DemandeHistoriqueDocument DHD
            JOIN DemandeCOT DP ON DHD.IDDemande = DP.Id
            JOIN dbo.Mo_Human H ON H.HumanID = DP.IdSouscripteur
            JOIN Un_Subscriber S ON S.SubscriberID = DP.IdSouscripteur AND S.AddressLost = 0
            WHERE DHD.CodeTypeDocument = 'le_nq_cot'
                AND DHD.EstEmis = 0
                AND LEFT(CONVERT(VARCHAR, DHD.DateCreation, 120), 10) BETWEEN @dtDateCreationDe AND @dtDateCreationA
                AND (H.LangID = @LangID OR @LangID IS NULL)

    SELECT
        IDDemande = D.Id,
        C.SubscriberID,
        A.Address,
        A.City,
        ZipCode = dbo.fn_Mo_FormatZIP(A.ZipCode, A.CountryID),
        A.StateName,
        HS.LastName AS nomSouscripteur,
        HS.FirstName AS prenomSouscripteur,
        LangID = HS.LangID,
        Sex.LongSexName AS appelLong,
        Sex.ShortSexName AS appelCourt,
        PrenomBenef = hb.FirstName,
        C.ConventionNo,
        C.BeneficiaryID,
        NomBenef = HB.LastName,
        AdresseBenef = AB.Address,
        CityBenef = AB.City,
        ZipCodeBenef = AB.ZipCode,
        StateNameBenef = AB.StateName,
        CountryBenef = AB.CountryID,
        AppelLongBenef = SexB.LongSexName,
        AppelCourtBenef = SexB.ShortSexName,
        IdRaisonRefus = D.IdRaisonRefus,
        RaisonRefusAutre = D.RaisonRefusAutre
    FROM Un_Convention C
    JOIN DemandeCOT D ON D.IdConvention = C.ConventionID
    JOIN @Demande De ON De.IDDemande = D.Id
    JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
    JOIN dbo.Mo_Human HS ON HS.HumanID = S.SubscriberID
    JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
    JOIN Mo_Sex Sex ON Sex.SexID = HS.SexID AND Sex.LangID = HS.LangID
    JOIN dbo.Mo_Adr A ON A.AdrID = HS.AdrID
    JOIN dbo.Mo_Adr AB ON AB.AdrID = HB.AdrID
    JOIN Mo_Sex SexB ON SexB.SexID = HB.SexID AND SexB.LangID = HB.LangID

END