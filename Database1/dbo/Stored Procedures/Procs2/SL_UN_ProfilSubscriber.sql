/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc
Nom                 : SL_UN_ProfilSubscriber
Description         : Récupération des données du profil souscripteur spécifié par @SubscriberID
Valeurs de retours  : Dataset
Exemple d'appel		: EXECUTE dbo.SL_UN_ProfilSubscriber 601617						

Note :				2008-09-19	Patrick Robitaille		Creation
					2009-12-18	Jean-François Gauthier	Ajout des champs liés au profil du souscripteur
					2010-01-05	Jean-François Gauthier	Modification des champs liés au profil souscripteur (modification de noms)
					2011-04-08	Corentin Menthonnex		2011-12 : ajout des champs suivants aux informations souscripteur vcJustifObjectifsInvestissement
					2011-10-31	Christian Chénard	Ajout des champs iID_Estimation_Cout_Etudes et iID_Estimation_Valeur_Nette_Menage
					2012-09-14	Donald Huppé			Ajout de iID_Tolerance_Risque
					2014-09-12	Pierre-Luc Simard	Récupérer uniquement le dernier profil souscripteur
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_ProfilSubscriber] (
							@SubscriberID INTEGER)
AS
BEGIN
	SELECT 
		iID_Profil_Souscripteur,
		iID_Souscripteur,
		iID_Connaissance_Placements,
		iID_Revenu_Familial,
		iID_Depassement_Bareme,
		iID_Identite_Souscripteur,
		iID_ObjectifInvestissementLigne1,
		iID_ObjectifInvestissementLigne2,
		iID_ObjectifInvestissementLigne3,
		tiNb_Personnes_A_Charge,
	    vcIdentiteVerifieeDescription,
		vcDepassementBaremeJustification,
		iIDNiveauEtudeMere,					-- 2010-01-05 : JFG : Modification des champs suivants
		iIDNiveauEtudePere,
		iIDNiveauEtudeTuteur,
		iIDImportanceEtude,
		iIDEpargneEtudeEnCours,
		iIDContributionFinanciereParent,
		vcJustifObjectifsInvestissement,	-- 2011-04-08 : + 2011-12 + CM
		iID_Estimation_Cout_Etudes,
		iID_Estimation_Valeur_Nette_Menage,
		iID_Tolerance_Risque
/*
		iIDNiveauEtudeParent,				-- 2009-12-18 : JFG :Ajout des champs suivants
		iIDImportanceEtudeMetier,
		iIDImportanceEtudeCollege,		
		iIDImportanceEtudeUniversite,	
		iIDEpargneEtudeEnCours,
		iIDContributionFinanciereParent */
	FROM tblCONV_ProfilSouscripteur PS
	WHERE 
		iID_Souscripteur = @SubscriberID
		AND DateProfilInvestisseur = (
			SELECT	
				MAX(PSM.DateProfilInvestisseur)
			FROM tblCONV_ProfilSouscripteur PSM
			WHERE PSM.iID_Souscripteur = PS.iID_Souscripteur
				AND PSM.DateProfilInvestisseur <= GETDATE()
			)
	ORDER BY 
		iID_Profil_Souscripteur
END
