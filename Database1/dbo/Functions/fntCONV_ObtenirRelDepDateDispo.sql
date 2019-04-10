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

/****************************************************************************************************
Code de service		:		dbo.fntCONV_ObtenirRelDepDateDispo
Nom du service		:		fntCONV_ObtenirRelDepDateDispo
But					:		Récupérer les dates de disponibilité des relevés de dépôt semestriels
Facette				:		
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
                        @bDisponible				Indique si on recherche les dates			OUI
													disponibles ou non
													1 = Dates dispo seulement
													0 = Toutes les dates                  
                        @bDateDebut					Indique si on recherche les dates			OUI
													de début ou non
													1 = Oui, 0 = Non, NULL = 0													

Exemple d'appel:
			SELECT * FROM [dbo].[fntCONV_ObtenirRelDepDateDispo](1,0)
			SELECT * FROM [dbo].[fntCONV_ObtenirRelDepDateDispo](0,1)


Parametres de sortie :  Table											Champs							Description
					    -----------------								---------------------------		--------------------------
					    tblCONV_ReleveDepotDateSemestrielleDisponible   iDateID							Identifiant unique de la date		            
																		dtDateReleveSemestriel			Date du relevé semestriel
																		bDateDisponible					Indique si la date est disponible pour consultation ou non
																		bDateDebut						Indique si la date est une date de début ou une date de fin
																										1 si c'est une date de début, 0 sinon

Historique des modifications :
	Date        Programmeur                 Description
	----------  ------------------------    ----------------------------------------------------------
	2009-10-02  Jean-François Gauthier      Création de la fonction           
	2010-09-21  Jean-Francois Arial         Ajout du tri sur les dates
	2011-06-28  Corentin Menthonnex         Ajout de la gestion des dates de début
    2017-09-27  Pierre-Luc Simard           Deprecated - Cette procédure n'est plus utilisée

  ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirRelDepDateDispo]
	( 
		@bDisponible	BIT,
		@bDateDebut		BIT
	)
RETURNS  
		@tDate TABLE 
		( 
			iDateID					INT, 
			dtDateReleveSemestriel	DATETIME, 
			bDateDisponible			BIT, 
			bDateDebut				BIT
		)
BEGIN			
    INSERT INTO @tDate
            (iDateID ,
             dtDateReleveSemestriel ,
             bDateDisponible ,
             bDateDebut
            )
    VALUES
            (0 , -- iDateID - int
             GETDATE() , -- dtDateReleveSemestriel - datetime
             NULL , -- bDateDisponible - bit
             NULL  -- bDateDebut - bit
            )
    RETURN
    
    /*
	IF @bDisponible = 1	-- RETOURNE UNIQUEMENT LES DATES DISPONIBLES
		BEGIN
			INSERT INTO @tDate
			(iDateID, dtDateReleveSemestriel, bDateDisponible)
			SELECT
				iDateID, dtDateReleveSemestriel, bDateDisponible
			FROM 
				dbo.tblCONV_ReleveDepotDateSemestrielleDisponible
			WHERE
				bDateDisponible = 1
				AND ISNULL(@bDateDebut,0) = bDateDebut
			ORDER BY dtDateReleveSemestriel
		END
	ELSE					-- RETOURNE TOUT
		BEGIN
			INSERT INTO @tDate
			(iDateID, dtDateReleveSemestriel, bDateDisponible)
			SELECT
				iDateID, dtDateReleveSemestriel, bDateDisponible
			FROM 
				dbo.tblCONV_ReleveDepotDateSemestrielleDisponible
			WHERE ISNULL(@bDateDebut,0) = bDateDebut
			ORDER BY dtDateReleveSemestriel
		END
	RETURN
    */
END