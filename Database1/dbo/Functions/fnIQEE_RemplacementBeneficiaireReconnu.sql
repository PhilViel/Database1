/***********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : fnIQEE_RemplacementBeneficiaireReconnu
Nom du service        : Remplacement de bénéficiaire reconnu
But                 : Déterminer si un changement de bénéficiaire est reconnu ou non avant de le faire.  Déterminer
                      si une transaction de remplacement de bénéficiaire pour l'IQÉÉ est reconnu ou non.
Facette                : IQEE

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        iID_Changement_Beneficiaire    Identifiant unique du changement de bénéficiaire.
                        iID_Convention                Identifiant unique de la convention qui fait l'objet d'un changement
                        iID_Ancien_Beneficiaire        Identifiant unique de l'ancien bénéficiaire.
                        iID_Nouveau_Beneficiaire    Identifiant unique du nouveau bénéficiaire.
                        dtDate_Changement_            Date du changement de bénéficiaire.
                            Beneficiaire
                        bLien_Frere_Soeur_Avec_        Indicateur de lien frère/soeur entre l'ancien et le nouveau
                            Ancien_Beneficiaire        bénéficiaire.
                        bLien_Sang_Avec_            Indicateur de lien de sans entre le nouveau bénéficiaire et le
                            Souscripteur_Initial    souscripteur initial.

Exemples d’appel    :    SELECT [dbo].[fnIQEE_RemplacementBeneficiaireReconnu](138117, NULL, NULL, NULL, NULL, NULL, NULL) -- 0
                        SELECT [dbo].[fnIQEE_RemplacementBeneficiaireReconnu](219218, NULL, NULL, NULL, NULL, NULL, NULL) -- 1
                        SELECT [dbo].[fnIQEE_RemplacementBeneficiaireReconnu](148754, NULL, NULL, NULL, NULL, NULL, NULL) -- 2
                        SELECT [dbo].[fnIQEE_RemplacementBeneficiaireReconnu](NULL, 127120, 239871, 239872,
                                                                              '2008-07-24 08:57:45.920', 1, 1)

SQL pour sortir des cas :
        SELECT CB.*,
                [dbo].[fnIQEE_RemplacementBeneficiaireReconnu](CB.iID_Changement_Beneficiaire, NULL, NULL, NULL, NULL, NULL, NULL),
                [dbo].[fn_Mo_Age](H1.BirthDate,CB.dtDate_Changement_Beneficiaire),
                [dbo].[fn_Mo_Age](H2.BirthDate,CB.dtDate_Changement_Beneficiaire)
        FROM [dbo].[fntCONV_RechercherChangementsBeneficiaire](NULL, NULL, NULL, NULL, NULL, NULL,
                                                                       NULL, NULL, NULL, NULL, NULL, NULL, NULL) CB
            JOIN MO_Human H1 ON H1.HumanID = CB.iID_Ancien_Beneficiaire
            JOIN MO_Human H2 ON H2.HumanID = CB.iID_Nouveau_Beneficiaire
        WHERE CB.dtDate_Changement_Beneficiaire >= '2008-01-01'
         AND [dbo].[fnIQEE_RemplacementBeneficiaireReconnu](CB.iID_Changement_Beneficiaire, NULL, NULL, NULL, NULL, NULL, NULL) = 1

Paramètres de sortie:       @bEstReconnu    TINYINT     1 = Changement de bénéficiaire reconnu
                                                        0 = Changement de bénéficiaire non reconnu

Historique des modifications:
    Date        Programmeur                 Description
    ----------  ------------------------    ---------------------------------------------------------------------
    2009-09-23  Éric Deshaies               Création du service                            
    2009-12-14  Éric Deshaies               Refonte du service
    2012-06-06  Éric Michaud                Modification projet septembre 2012
    2014-03-14  Stéphane Barbeau		    Refonte de la logique avec les conditions officielles de changement de bénéficiaire reconnu
    2016-05-04  Steeve Picard               Renommage de la fonction «fnIQEE_ObtenirDateEnregistrementRQ» qui était auparavant «fnIQEE_ObtenirDateEnregistrementRQ»
    2016-09-29  Steeve Picard               Optimisation en utilisant @iAge_Ancien_Beneficiaire & @iAge_Nouveau_Beneficiaire
    2016-11-25  Steeve Picard               Correction pour les changements de bénéficiaire effectués en 2011 & 2012
    2017-05-25  Steeve Picard               Modification pour les indicateurs «bLien_Frere_Soeur, bLien_Sang_Nouveau_Beneficiaire_Souscripteur_Initial» dont la condition «moins de 21 ans» est manquante dans le NID d'IQÉÉ
    2017-11-16  Steeve Picard               Enlever la condition sur la majoration quand ce n'est pas une fraterie
***********************************************************************************************************************/
CREATE FUNCTION dbo.fnIQEE_RemplacementBeneficiaireReconnu
(
    @iID_Changement_Beneficiaire INT,
    @iID_Convention INT,
    @iID_Ancien_Beneficiaire INT,
    @iID_Nouveau_Beneficiaire INT,
    @dtDate_Changement_Beneficiaire DATETIME,
    @bLien_Frere_Soeur_Avec_Ancien_Beneficiaire BIT,
    @bLien_Sang_Avec_Souscripteur_Initial BIT
)
RETURNS TINYINT
AS
BEGIN
    DECLARE @bEstReconnu BIT = 0,
            @iIQEE_LIMITE_AGE_REMPLACEMENT_BENEF_RECONNU INT,
            @iAge_Nouveau_Beneficiaire int,
            @iAge_Ancien_Beneficiaire int

    -- Retourner -1 s'il manque des informations requises
    IF @iID_Changement_Beneficiaire IS NULL AND
       (@iID_Convention IS NULL OR
        @iID_Ancien_Beneficiaire IS NULL OR
        @iID_Nouveau_Beneficiaire IS NULL OR
        @dtDate_Changement_Beneficiaire IS NULL OR
        @bLien_Frere_Soeur_Avec_Ancien_Beneficiaire IS NULL OR
        @bLien_Sang_Avec_Souscripteur_Initial IS NULL)
        RETURN -1

    -- Rechercher les informations du changement de bénéficiaire s'il existe déjà
    IF @iID_Changement_Beneficiaire IS NOT NULL AND
       (@iID_Convention IS NULL OR
        @iID_Ancien_Beneficiaire IS NULL OR
        @iID_Nouveau_Beneficiaire IS NULL OR
        @dtDate_Changement_Beneficiaire IS NULL OR
        @bLien_Frere_Soeur_Avec_Ancien_Beneficiaire IS NULL OR
        @bLien_Sang_Avec_Souscripteur_Initial IS NULL)
        SELECT @iID_Convention = CB.iID_Convention,
               @iID_Ancien_Beneficiaire = CB.iID_Ancien_Beneficiaire,
               @iID_Nouveau_Beneficiaire = CB.iID_Nouveau_Beneficiaire,
               @dtDate_Changement_Beneficiaire = CB.dtDate_Changement_Beneficiaire,
               @bLien_Frere_Soeur_Avec_Ancien_Beneficiaire = CB.bLien_Frere_Soeur_Avec_Ancien_Beneficiaire,
               @bLien_Sang_Avec_Souscripteur_Initial = CB.bLien_Sang_Avec_Souscripteur_Initial
        FROM dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, @iID_Changement_Beneficiaire, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL) CB

    -- Présumer que le remplacement est reconnu

    SET @iIQEE_LIMITE_AGE_REMPLACEMENT_BENEF_RECONNU = CAST(dbo.fnGENE_ObtenirParametre('IQEE_LIMITE_AGE_REMPLACEMENT_BENEF_RECONNU', @dtDate_Changement_Beneficiaire, NULL, NULL, NULL, NULL, NULL) AS INT);

    SELECT @iAge_Nouveau_Beneficiaire = dbo.fn_Mo_Age(BirthDate, @dtDate_Changement_Beneficiaire)
      FROM dbo.Mo_Human
     WHERE HumanID = @iID_Nouveau_Beneficiaire

	IF @iAge_Nouveau_Beneficiaire < @iIQEE_LIMITE_AGE_REMPLACEMENT_BENEF_RECONNU
	BEGIN
		IF @bLien_Frere_Soeur_Avec_Ancien_Beneficiaire <> 0
			SET @bEstReconnu = 1
		ELSE 
		BEGIN
			SELECT @iAge_Ancien_Beneficiaire = dbo.fn_Mo_Age(BirthDate, @dtDate_Changement_Beneficiaire)
			  FROM dbo.Mo_Human
			 WHERE HumanID = @iID_Ancien_Beneficiaire

			IF @bLien_Sang_Avec_Souscripteur_Initial <> 0 and @iAge_Ancien_Beneficiaire < @iIQEE_LIMITE_AGE_REMPLACEMENT_BENEF_RECONNU
				SET @bEstReconnu = 1
		END
    END

    RETURN @bEstReconnu
END
