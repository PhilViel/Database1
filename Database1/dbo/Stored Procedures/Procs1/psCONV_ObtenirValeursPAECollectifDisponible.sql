/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */
/********************************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		:	psCONV_ObtenirValeursPAECollectifDisponible 
Nom du service		:	Permet d'obtenir les valeurs admissibles à un PAE pour un régime collectif 
But 				: 
Facette			:		CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

	EXEC psCONV_ObtenirValeursPAECollectifDisponible 103365
	
Paramètres de sortie:	

Historique des modifications:
		Date				Programmeur							Description									Référence
		------------		----------------------------------	-----------------------------------------	------------
		2017-12-06	        Pierre-Luc Simard					Création du service	
        2018-10-31          Pierre-Luc Simard                   Ajout du supplément
        2018-11-09          Pierre-Luc Simard                   Ajout du nombre d'unités convertis
        2018-11-12          Pierre-Luc Simard                   N'est plus utilisée par Proacces

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirValeursPAECollectifDisponible] 
(
	@iConventionID INT
)
AS
BEGIN

    SELECT 1/0
    /*
    SELECT 
        ConventionID,
        ConventionNo,
        NB_Unites_Convention,
        NB_Unites_Convention_Convertie,
        bRIN_Verse,
        Depot,
        MontantSouscrit,
        Taux_Avancement,
        NB_Unites_PAE_Verse,
        NB_Unites_Disponibles_PAE,
        Nb_Unites_Disponibles_PAE_Convertie,
        RistourneAss,
        QuotePart,
        mQuantite_UniteSupplementAccorde,
        mQuantite_UniteSupplementDemande,
        mQuantite_UniteSupplementDisponible,
        Nb_Unites_Supplement_Disponibles_PAE_Convertie,
        mMontant_Supplement_Disponible_PAE 
    FROM dbo.fntCONV_ObtenirValeursPAECollectifDisponible(@iConventionID)

	OPTION(RECOMPILE);
    */
END