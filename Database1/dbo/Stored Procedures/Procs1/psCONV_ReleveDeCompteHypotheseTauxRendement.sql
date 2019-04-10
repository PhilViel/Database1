

/********************************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	psCONV_ReleveDeCompteHypotheseTauxRendement
Description         :	
Valeurs de retours  :	Dataset de données

Note                :	
					2015-10-07	Donald Huppé	Création 
					
exec psCONV_ReleveDeCompteHypotheseTauxRendement 2014
*********************************************************************************************************************/


CREATE PROCEDURE [dbo].[psCONV_ReleveDeCompteHypotheseTauxRendement] (
		@year int = 2015

	)
AS
BEGIN

select 
	AnneeReleveCompte
	,TAUX_REVENU_ACCUMULE
	,TAUX_REVENU_ACCUMULE_COMPTE_PAE
 from tblCONV_ReleveDeCompteHypotheseTauxRendement 
 where AnneeReleveCompte = @year


end