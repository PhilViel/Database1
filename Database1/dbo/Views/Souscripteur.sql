
--
-- Création des vues nécessaires pour les entitées 
-- 

CREATE VIEW [dbo].[Souscripteur] AS
SELECT
[SubscriberID] AS HumanID,
[RepID],
[StateID],
[ScholarshipLevelID],
[AnnualIncome],
[SemiAnnualStatement],
[BirthLangID],
[AddressLost],
[tiCESPState],
[Spouse],
[Contact1],
[Contact2],
[Contact1Phone],
[Contact2Phone],
[iID_Preference_Suivi],
[bSouscripteur_Desire_Releve_Elect],
[bConsentement],
[bRapport_Annuel_Direction],
[bEtats_Financiers_Annuels],
[bEtats_Financiers_Semestriels],
[iID_Identite_Souscripteur],
[vcIdentiteVerifieeDescription],
[bAutorisation_Resiliation]
FROM [dbo].[Un_Subscriber]
