

/********************************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	psCONV_ReleveDeCompteRendementRegime
Description         :	
Valeurs de retours  :	Dataset de données

Note                :	
					2015-08-12	Donald Huppé	Création 
					
exec psCONV_ReleveDeCompteRendementRegime 2014, 1
*********************************************************************************************************************/


CREATE PROCEDURE [dbo].[psCONV_ReleveDeCompteRendementRegime] (
		@year int = 2015,
		@iID_Regroupement_Regime int

	)
AS
BEGIN

select 
	AnneeReleveCompte,
	iID_Regroupement_Regime, 	
	Brut1,  	
	Brut3, 	
	Brut5, 	
	Brut10,
	Frais1,
	Frais3,
	Frais5,
	Frais10,
	Net1,
	Net3,
	Net5,
	Net10
 from tblCONV_ReleveDeCompteRendementRegime 
 where AnneeReleveCompte = @year
 and iID_Regroupement_Regime = @iID_Regroupement_Regime

end