/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc

Nom                 : SL_CHQ_LastCheckNumber
Description         : Procédure qui retournera le plus grand numéro de chèque.
Valeurs de retours  : 
Dataset             : iCheckNumber	INTEGER Plus grand numéro de chèque

Exemple d’appel     : EXECUTE [dbo].[SL_CHQ_LastCheckNumber] NULL
                      EXECUTE [dbo].[SL_CHQ_LastCheckNumber] 1
					  EXECUTE [dbo].[SL_CHQ_LastCheckNumber] 2
					  EXECUTE [dbo].[SL_CHQ_LastCheckNumber] 3
					  
Historique des modifications:
               Date          Programmeur                        Description
               ------------  ---------------------------------- ---------------------------
ADX0000714  IA 2005-09-13    Bruno Lapointe                     Création
               2010-06-02    Danielle Côté                      ajout traitement fiducies distinctes par régime
			   2018-09-17	 Donald Huppé						Patch pour utiliser les chq de 30007 à 30899 (voir Isabelle girard) Elle va rappeler pour enlever ça
			   2018-12-07	 Donald Huppé						Enlever patch précédente
****************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_LastCheckNumber]
(
   @iID_Regroupement_Regime INT  -- ID de regroupement de régimes
)
AS
BEGIN

   -------------------------------------------------------------------------
   -- Retourner le dernier numéro de chèque d'un regroupement de régime.
	-- Si l'ID de regroupement de régime est NULL, prendre le plus grand
	-- numéro de chèque sans distinction de regroupement de régime pour
	-- les talons de chèques orphelin.
   ------------------------------------------------------------------------- 
   IF @iID_Regroupement_Regime IS NOT NULL
   BEGIN
      SELECT iCheckNumber = ISNULL(MAX(iCheckNumber),0)
        FROM CHQ_Check
       WHERE iID_Regime IN (SELECT iID_Plan FROM [dbo].[fntCONV_ObtenirRegimes](@iID_Regroupement_Regime))
   END
   ELSE
   BEGIN
      SELECT iCheckNumber = ISNULL(MAX(iCheckNumber),0)
        FROM CHQ_Check	
   END	

END
