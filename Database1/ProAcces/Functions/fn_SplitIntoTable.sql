CREATE FUNCTION [ProAcces].[fn_SplitIntoTable] (
	@list varchar(MAX), 
	@SplitChar varchar(2) = ','
)
RETURNS @tbl TABLE (rowID int identity(1,1), strField varchar(MAX))
AS
/****************************************************************************************************
Code de service		:		ProAcces.fn_SplitIntoTable
Nom du service		:		Divise une chaine de charactères separées par un charactère passé en paramètre
But					:		Convertir un liste de valeurs dans une table
Facette				:		ProAcces
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@list						Liste des valeurs
						@SplitChar					Charactère separateur
Exemple d'appel:                
                SELECT * FROM ProAcces.fn_SplitIntoTable('1,2,3,4',',')

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
                        @tbl						rowID										position des éléments dans la liste
                        @tbl						strField									valeur des elements de la liste
                    
Historique des modifications :		
						Date						Programmeur									Description							Référence
						----------					-------------------------------------		----------------------------		---------------
						2015-07-20					Steve Picard								Création de la fonction           
****************************************************************************************************/
BEGIN
	DECLARE @POS int

	SELECT @POS=CharIndex(@SplitChar,@List)
	WHILE @Pos>0 BEGIN
		INSERT INTO @tbl(strField) 
		SELECT SubString(@list, 1 ,@pos-1)

		SET @list = SUBSTRING(@list, @Pos+len(@SplitChar), len(@List))
		
		SELECT @POS=CharIndex(@SplitChar,@List) --,@LastPos)
	End

	IF Len(@list) > 0 
		INSERT INTO @tbl (strField) VALUES (@list)				
	RETURN 
END 
