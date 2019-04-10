
/****************************************************************************************************
Code de service		:		fn_Mo_DateToLongDateStr
Nom du service		:		
But					:		Afficher une date en format long et texte dans une langue reçue en paramètre.
Description			:		

Facette				:		GENE
Reférence			:		???

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						FDate						Date que l'on veut afficher en monde texte (long)
						FLang						Language pour le format de date FRA = French / ENU = English / UNK = Unknown

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       S/O                          @FDateStr                                   Date en texte selon la langue
																								
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
 						2010-03-10					Pierre Paquet							Utilisation des CHAR(160) plutôt que des ' '.
 ****************************************************************************************************/


CREATE FUNCTION [dbo].[fn_Mo_DateToLongDateStr]
( @FDate       MoDate,
  @FLang       MoLang     -- Language  FRA = French / ENU = English / UNK = Unknown
)
RETURNS MoDesc
AS
BEGIN
DECLARE
  @FDateStr  MoDesc,
  @FMonthStr MoDesc;

  IF (dbo.fn_Mo_DateNoTime(@FDate)) IS NULL
    RETURN('')

  --Default setting is in english
  SET @FMonthStr = dbo.fn_Mo_TranslateMonthToStr(@FDate, @FLang)

  IF @FLang = 'FRA'
    --SET @FDateStr = RTRIM(LTRIM(DATENAME(Day, @FDate))) + ' ' + @FMonthStr + ' ' + RTRIM(LTRIM(DATENAME(Year, @FDate)))
	SET @FDateStr = RTRIM(LTRIM(DATENAME(Day, @FDate))) + CHAR(160) + @FMonthStr + CHAR(160) + RTRIM(LTRIM(DATENAME(Year, @FDate)))
  ELSE
    --SET @FDateStr = @FMonthStr + ' ' + RTRIM(LTRIM(DATENAME(Day, @FDate)))  + ', ' + RTRIM(LTRIM(DATENAME(Year, @FDate)))
	 SET @FDateStr = @FMonthStr + CHAR(160) + RTRIM(LTRIM(DATENAME(Day, @FDate)))  + ',' + CHAR(160) + RTRIM(LTRIM(DATENAME(Year, @FDate)))

  RETURN(@FDateStr)
END


