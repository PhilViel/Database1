/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_RechercherFichiers
Nom du service        : Rechercher des fichiers
But                 : Rechercher à travers les fichiers de l’IQÉÉ et obtenir les informations des fichiers.
Facette                : IQÉÉ

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        cID_Langue                    Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
                                                    Le français est la langue par défaut si elle n’est pas spécifiée.
                        iID_Fichier_IQEE            Identifiant unique du fichier de l’IQÉÉ.  S’il est vide, tous les
                                                    fichiers sont considérés.
                        siAnnee_Fiscale                Année fiscale du fichier.  Si elle est vide, toutes les années sont
                                                    considérées.
                        dtDate_Debut_Creation        Date de début de création/importation du fichier.  Si elle est vide,
                                                    toutes les dates de création sont considérées ou jusqu’à la date de
                                                    fin si elle est présente.
                        dtDate_Fin_Creation            Date de fin de création/importation du fichier.  Si elle est vide,
                                                    toutes les dates de création sont considérées ou à partir de la date
                                                    de début si elle est présente.
                        tiID_Type_Fichier            Type de fichier.  S’il est vide, tous les types sont considérés.
                        bFichier_Test                Indicateur de fichier test.  S’il est vide, tous les types de fichier
                                                    sont considérés.
                        tiID_Statut_Fichier            Statut du fichier.  S’il est vide, tous les statuts sont considérés.
                        bInd_Simulation                Indicateur de simulation.  Égal à 1 signifie de rechercher uniquement
                                                    les simulations, égal à 0 signifie de rechercher que les fichiers
                                                    disponibles à l’utilisateur.  S’il est vide, tous les types de fichier
                                                    sont considérés.
                        vcCode_Simulation            Code de simulation spécifique.  Recherche un fichier résultat d’une
                                                    ou plusieurs simulations de transactions à venir.
                        vcCode_Type_Fichier            Code du type de fichier.  S’il est vide, tous les types sont considérés.
                        vcCode_Statut                Code du statut de fichier.  S’il est vide, tous les statuts sont considérés.
                        vcNom_Fichier                Nom du fichier de l'IQÉÉ.  S'il est vide, tous les fichiers sont considérés.


Exemple d’appel        :    EXECUTE [dbo].[psIQEE_RechercherFichiers] NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL

Paramètres de sortie:    Tous les champs de la fonction "fntIQEE_RechercherFichiers".

Historique des modifications:
    Date        Programmeur                    Description
    ----------    ------------------------    -------------------------------------------------------
    2009-11-23    Éric Deshaies                Création du service                        
    2011-04-08    Éric Deshaies                Ajout de nouveaux paramètres et champs de sortie
    2018-02-08  Steeve Picard               Déplacement du «Order By» à l'extérieure de «fntIQEE_RechercherFichiers»
****************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_RechercherFichiers 
(
    @cID_Langue CHAR(3),
    @iID_Fichier_IQEE INT,
    @siAnnee_Fiscale SMALLINT,
    @dtDate_Debut_Creation DATETIME,
    @dtDate_Fin_Creation DATETIME,
    @tiID_Type_Fichier TINYINT,
    @bFichier_Test BIT,
    @tiID_Statut_Fichier TINYINT,
    @bInd_Simulation BIT,
    @vcCode_Simulation VARCHAR(100),
    @vcCode_Type_Fichier VARCHAR(3),
    @vcCode_Statut VARCHAR(3),
    @vcNom_Fichier VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Considérer le français comme la langue par défaut
    IF @cID_Langue IS NULL
        SET @cID_Langue = 'FRA'

    -- Si l'identifiant de fichier est 0, c'est comme s'il n'est pas là
    IF @iID_Fichier_IQEE = 0
        SET @iID_Fichier_IQEE = NULL

    -- Si les années fiscales sont à 0, c'est comme si elles n'étaient pas là
    IF @siAnnee_Fiscale = 0
        SET @siAnnee_Fiscale = NULL

    -- Si le type de fichier est 0, c'est comme s'il n'est pas là
    IF @tiID_Type_Fichier = 0
        SET @tiID_Type_Fichier = NULL

    -- Si le statut de fichier est 0, c'est comme s'il n'est pas là
    IF @tiID_Statut_Fichier = 0
        SET @tiID_Statut_Fichier = NULL

    SELECT * FROM dbo.fntIQEE_RechercherFichiers(@iID_Fichier_IQEE, @siAnnee_Fiscale, @siAnnee_Fiscale, @dtDate_Debut_Creation, @dtDate_Fin_Creation, @tiID_Type_Fichier, 
                                                 @bFichier_Test, @tiID_Statut_Fichier, @bInd_Simulation, @vcCode_Simulation, @vcCode_Type_Fichier, @vcCode_Statut, @vcNom_Fichier)
     WHERE siAnnee_Fiscale IS NOT NULL 
     ORDER BY siAnnee_Fiscale DESC, dtDate_Creation DESC 
END
